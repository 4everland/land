// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/ILandCore.sol";
import "../interfaces/IPriceFeed.sol";
import "../libraries/LandMath.sol";
import "../dependencies/LandOwnable.sol";
import "../dependencies/console.sol";

contract PriceFeed is IPriceFeed, LandOwnable {
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

	error PriceFeed__InvalidFeedResponseError();
	error PriceFeed__FeedFrozenError();
	error PriceFeed__UnknownFeedError();
	error PriceFeed__HeartbeatOutOfBoundsError();

	event NewOracleRegistered(address chainlinkAggregator);
	event PriceFeedStatusUpdated(address oracle, bool isWorking);
	event PriceRecordUpdated(uint256 _price);

	// Used to convert a chainlink price answer to an 18-digit precision uint
	uint256 public constant TARGET_DIGITS = 18;

	// Responses are considered stale this many seconds after the oracle's heartbeat
	uint256 public constant RESPONSE_TIMEOUT_BUFFER = 1 hours;

	// Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
	uint256 public constant MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 5e17; // 50%

	OracleRecord public oracleRecord;
	PriceRecord public priceRecord;

	constructor(ILandCore _LandCore, address _chainlinkOracle, uint32 _heartbeat) LandOwnable(_LandCore) {
		_setOracle(_chainlinkOracle, _heartbeat);
	}

	/**
        @notice Set the oracle for a specific token
        @param _chainlinkOracle Address of the chainlink oracle for this LST
        @param _heartbeat Oracle heartbeat, in seconds
     */
	function setOracle(address _chainlinkOracle, uint32 _heartbeat) public onlyOwner {
		_setOracle(_chainlinkOracle, _heartbeat);
	}

	function _setOracle(address _chainlinkOracle, uint32 _heartbeat) internal {
		if (_heartbeat > 86400) revert PriceFeed__HeartbeatOutOfBoundsError();
		IAggregatorV3Interface newFeed = IAggregatorV3Interface(_chainlinkOracle);
		(FeedResponse memory currResponse, FeedResponse memory prevResponse, ) = _fetchFeedResponses(newFeed, 0);

		if (!_isFeedWorking(currResponse, prevResponse)) {
			revert PriceFeed__InvalidFeedResponseError();
		}
		if (_isPriceStale(currResponse.timestamp, _heartbeat)) {
			revert PriceFeed__FeedFrozenError();
		}

		OracleRecord memory record = OracleRecord({ chainLinkOracle: newFeed, decimals: newFeed.decimals(), heartbeat: _heartbeat, isFeedWorking: true });

		oracleRecord = record;
		_processFeedResponses(record, currResponse, prevResponse);
		emit NewOracleRegistered(_chainlinkOracle);
	}

	function fetchPrice() public returns (uint256) {
		if (priceRecord.lastUpdated == block.timestamp) {
			// We short-circuit only if the price was already correct in the current block
			return priceRecord.scaledPrice;
		}
		if (priceRecord.lastUpdated == 0) {
			revert PriceFeed__UnknownFeedError();
		}

		OracleRecord storage oracle = oracleRecord;

		(FeedResponse memory currResponse, FeedResponse memory prevResponse, bool updated) = _fetchFeedResponses(oracle.chainLinkOracle, priceRecord.roundId);

		if (!updated) {
			if (_isPriceStale(priceRecord.timestamp, oracle.heartbeat)) {
				revert PriceFeed__FeedFrozenError();
			}
			return priceRecord.scaledPrice;
		}

		return _processFeedResponses(oracle, currResponse, prevResponse);
	}

	function _processFeedResponses(OracleRecord memory oracle, FeedResponse memory _currResponse, FeedResponse memory _prevResponse) internal returns (uint256) {
		uint8 decimals = oracle.decimals;
		bool isValidResponse = _isFeedWorking(_currResponse, _prevResponse) && !_isPriceStale(_currResponse.timestamp, oracle.heartbeat) && !_isPriceChangeAboveMaxDeviation(_currResponse, _prevResponse, decimals);
		if (isValidResponse) {
			uint256 scaledPrice = _scalePriceByDigits(uint256(_currResponse.answer), decimals);
			if (!oracle.isFeedWorking) {
				_updateFeedStatus(oracle, true);
			}
			_storePrice(scaledPrice, _currResponse.timestamp, _currResponse.roundId);
			return scaledPrice;
		} else {
			if (oracle.isFeedWorking) {
				_updateFeedStatus(oracle, false);
			}
			if (_isPriceStale(priceRecord.timestamp, oracle.heartbeat)) {
				revert PriceFeed__FeedFrozenError();
			}
			return priceRecord.scaledPrice;
		}
	}

	function _calcEthPrice(uint256 ethAmount) internal returns (uint256) {
		uint256 ethPrice = fetchPrice();
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
		return block.timestamp - _priceTimestamp > _heartbeat + RESPONSE_TIMEOUT_BUFFER;
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

	function _updateFeedStatus(OracleRecord memory _oracle, bool _isWorking) internal {
		oracleRecord.isFeedWorking = _isWorking;
		emit PriceFeedStatusUpdated(address(_oracle.chainLinkOracle), _isWorking);
	}

	function _storePrice(uint256 _price, uint256 _timestamp, uint80 roundId) internal {
		priceRecord = PriceRecord({ scaledPrice: uint96(_price), timestamp: uint32(_timestamp), lastUpdated: uint32(block.timestamp), roundId: roundId });
		emit PriceRecordUpdated(_price);
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
