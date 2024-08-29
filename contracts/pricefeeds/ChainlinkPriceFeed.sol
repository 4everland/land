// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IAggregatorV3Interface.sol";
import "../dependencies/LandOwnable.sol";
import "../dependencies/console.sol";
import "../libraries/LandMath.sol";

contract ChainlinkPriceFeed is LandOwnable {
	struct OracleRecord {
		IAggregatorV3Interface chainLinkOracle;
		uint8 decimals;
		uint32 heartbeat;
		bool isFeedWorking;
	}

	struct PriceRecord {
		uint96 scaledPrice;
		uint32 timestamp;
		uint32 lastUpdated;
		uint80 roundId;
	}

	struct FeedResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
	}

	error PriceFeed__InvalidFeedResponseError(address token);
	error PriceFeed__FeedFrozenError(address token);
	error PriceFeed__UnknownFeedError(address token);
	error PriceFeed__HeartbeatOutOfBoundsError();

	event NewOracleRegistered(address token, address chainlinkAggregator);
	event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
	event PriceRecordUpdated(address indexed token, uint256 _price);

	uint256 public constant TARGET_DIGITS = 18;

	uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%

	mapping(address => OracleRecord) public oracleRecords;
	mapping(address => PriceRecord) public priceRecords;

	constructor(ILandCore _core, address _token, address _chainlinkOracle, uint32 _heartbeat) LandOwnable(_core) {
		_setOracle(_token, _chainlinkOracle, _heartbeat);
	}

	function setOracle(address _token, address _chainlinkOracle, uint32 _heartbeat) external onlyGuardian {
		_setOracle(_token, _chainlinkOracle, _heartbeat);
	}

	function _setOracle(address _token, address _chainlinkOracle, uint32 _heartbeat) internal {
		if (_heartbeat > 86400) revert PriceFeed__HeartbeatOutOfBoundsError();
		IAggregatorV3Interface newFeed = IAggregatorV3Interface(_chainlinkOracle);
		(FeedResponse memory currResponse, FeedResponse memory prevResponse, ) = _fetchFeedResponses(newFeed, 0);

		if (!_isFeedWorking(currResponse, prevResponse)) {
			revert PriceFeed__InvalidFeedResponseError(_token);
		}
		if (_isPriceStale(currResponse.timestamp, _heartbeat)) {
			revert PriceFeed__FeedFrozenError(_token);
		}

		OracleRecord memory record = OracleRecord({ chainLinkOracle: newFeed, decimals: newFeed.decimals(), heartbeat: _heartbeat,  isFeedWorking: true });

		oracleRecords[_token] = record;
		PriceRecord memory _priceRecord = priceRecords[_token];

		_processFeedResponses(_token, record, currResponse, prevResponse, _priceRecord);
		emit NewOracleRegistered(_token, _chainlinkOracle);
	}

	function fetchPrice(address _token) public returns (uint256) {
		PriceRecord memory priceRecord = priceRecords[_token];
		if (priceRecord.lastUpdated == block.timestamp) {
			// We short-circuit only if the price was already correct in the current block
			return priceRecord.scaledPrice;
		}
		if (priceRecord.lastUpdated == 0) {
			revert PriceFeed__UnknownFeedError(_token);
		}

		OracleRecord storage oracle = oracleRecords[_token];

		(FeedResponse memory currResponse, FeedResponse memory prevResponse, bool updated) = _fetchFeedResponses(oracle.chainLinkOracle, priceRecord.roundId);

		if (!updated) {
			if (_isPriceStale(priceRecord.timestamp, oracle.heartbeat)) {
				revert PriceFeed__FeedFrozenError(_token);
			}
			return priceRecord.scaledPrice;
		}

		return _processFeedResponses(_token, oracle, currResponse, prevResponse, priceRecord);
	}

	// Internal functions -----------------------------------------------------------------------------------------------

	function _processFeedResponses(address _token, OracleRecord memory oracle, FeedResponse memory _currResponse, FeedResponse memory _prevResponse, PriceRecord memory priceRecord) internal returns (uint256) {
		uint8 decimals = oracle.decimals;
		bool isValidResponse = _isFeedWorking(_currResponse, _prevResponse) && !_isPriceStale(_currResponse.timestamp, oracle.heartbeat) && !_isPriceChangeAboveMaxDeviation(_currResponse, _prevResponse, decimals);
		if (isValidResponse) {
			uint256 scaledPrice = _scalePriceByDigits(uint256(_currResponse.answer), decimals);
			if (!oracle.isFeedWorking) {
				_updateFeedStatus(_token, oracle, true);
			}
			_storePrice(_token, scaledPrice, _currResponse.timestamp, _currResponse.roundId);
			return scaledPrice;
		} else {
			if (oracle.isFeedWorking) {
				_updateFeedStatus(_token, oracle, false);
			}
			if (_isPriceStale(priceRecord.timestamp, oracle.heartbeat)) {
				revert PriceFeed__FeedFrozenError(_token);
			}
			return priceRecord.scaledPrice;
		}
	}

	function _calcEthPrice(uint256 ethAmount) internal returns (uint256) {
		uint256 ethPrice = fetchPrice(address(0));
		return (ethPrice * ethAmount) / 1 ether;
	}

	function _fetchFeedResponses(IAggregatorV3Interface oracle, uint80 lastRoundId) internal view returns (FeedResponse memory currResponse, FeedResponse memory prevResponse, bool updated) {
		currResponse = _fetchCurrentFeedResponse(oracle);
		if (lastRoundId == 0 || currResponse.roundId > lastRoundId) {
			prevResponse = _fetchPrevFeedResponse(oracle, currResponse.roundId);
			updated = true;
		}
	}

	function _isPriceStale(uint256 _priceTimestamp, uint256 _heartbeat) internal view returns (bool) {
		return block.timestamp - _priceTimestamp > _heartbeat;
	}

	function _isFeedWorking(FeedResponse memory _currentResponse, FeedResponse memory _prevResponse) internal view returns (bool) {
		return _isValidResponse(_currentResponse) && _isValidResponse(_prevResponse);
	}

	function _isValidResponse(FeedResponse memory _response) internal view returns (bool) {
		return (_response.success) && (_response.roundId != 0) && (_response.timestamp != 0) && (_response.timestamp <= block.timestamp) && (_response.answer != 0);
	}

	function _isPriceChangeAboveMaxDeviation(FeedResponse memory _currResponse, FeedResponse memory _prevResponse, uint8 decimals) internal pure returns (bool) {
		uint256 currentScaledPrice = _scalePriceByDigits(uint256(_currResponse.answer), decimals);
		uint256 prevScaledPrice = _scalePriceByDigits(uint256(_prevResponse.answer), decimals);

		uint256 minPrice = LandMath._min(currentScaledPrice, prevScaledPrice);
		uint256 maxPrice = LandMath._max(currentScaledPrice, prevScaledPrice);

		/*
		 * Use the larger price as the denominator:
		 * - If price decreased, the percentage deviation is in relation to the previous price.
		 * - If price increased, the percentage deviation is in relation to the current price.
		 */
		uint256 percentDeviation = ((maxPrice - minPrice) * LandMath.DECIMAL_PRECISION) / maxPrice;

		return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
	}

	function _scalePriceByDigits(uint256 _price, uint256 _answerDigits) internal pure returns (uint256) {
		if (_answerDigits == TARGET_DIGITS) {
			return _price;
		} else if (_answerDigits < TARGET_DIGITS) {
			// Scale the returned price value up to target precision
			return _price * (10 ** (TARGET_DIGITS - _answerDigits));
		} else {
			// Scale the returned price value down to target precision
			return _price / (10 ** (_answerDigits - TARGET_DIGITS));
		}
	}

	function _updateFeedStatus(address _token, OracleRecord memory _oracle, bool _isWorking) internal {
		oracleRecords[_token].isFeedWorking = _isWorking;
		emit PriceFeedStatusUpdated(_token, address(_oracle.chainLinkOracle), _isWorking);
	}

	function _storePrice(address _token, uint256 _price, uint256 _timestamp, uint80 roundId) internal {
		priceRecords[_token] = PriceRecord({ scaledPrice: uint96(_price), timestamp: uint32(_timestamp), lastUpdated: uint32(block.timestamp), roundId: roundId });
		emit PriceRecordUpdated(_token, _price);
	}

	function _fetchCurrentFeedResponse(IAggregatorV3Interface _priceAggregator) internal view returns (FeedResponse memory response) {
		try _priceAggregator.latestRoundData() returns (uint80 roundId, int256 answer, uint256 /* startedAt */, uint256 timestamp, uint80 /* answeredInRound */) {
			// If call to Chainlink succeeds, return the response and success = true
			response.roundId = roundId;
			response.answer = answer;
			response.timestamp = timestamp;
			response.success = true;
		} catch {
			// If call to Chainlink aggregator reverts, return a zero response with success = false
			return response;
		}
	}

	function _fetchPrevFeedResponse(IAggregatorV3Interface _priceAggregator, uint80 _currentRoundId) internal view returns (FeedResponse memory prevResponse) {
		if (_currentRoundId == 0) {
			return prevResponse;
		}
		unchecked {
			try _priceAggregator.getRoundData(_currentRoundId - 1) returns (uint80 roundId, int256 answer, uint256 /* startedAt */, uint256 timestamp, uint80 /* answeredInRound */) {
				prevResponse.roundId = roundId;
				prevResponse.answer = answer;
				prevResponse.timestamp = timestamp;
				prevResponse.success = true;
			} catch {}
		}
	}
}
