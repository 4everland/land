// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./Land.sol";
import "./interfaces/IPriceFeed.sol";
import "./proxy/AdminWrapper.sol";
import "./libraries/Path.sol";
import "./dependencies/console.sol";

contract UNILand is Land, AdminWrapper {
	IQuoter public quoter;
	bytes public path;

	function initialize(ILandCore _core, IQuoter _quoter, bytes memory _path, ICoin[] memory _coins) external initializer {
		__InitCore(_core);
		quoter = _quoter;
		path = _path;
		for (uint256 i = 0; i < _coins.length; i++) {
			_addCoin(_coins[i]);
		}
	}

	function mintByETH(bytes32 account) external payable {
		require(!paused, "UNILand: paused");
		(address _WETH, address usd,) = Path.decodeFirstPool(path);
		ICoin WETH = ICoin(_WETH);
		// can be attacked by flash loan here
		uint256 value = quoter.quoteExactInput(path, msg.value);
		uint8 decimals = ICoin(usd).decimals();
		uint256 coinAmount = formatValue(value, decimals);
		uint256 landAmount = coinAmount * landPerCoin;
		balances[account] += landAmount;
		deposits[account][WETH] += msg.value;
		emit Mint(account, WETH, msg.value, coinAmount, landAmount, balances[account]);
	}

	function upgradeWith(IQuoter _quoter, bytes memory _path) external onlyAdmin {
		quoter = _quoter;
		path = _path;
	}

	function formatValue(uint256 amount, uint8 decimals) public pure returns(uint256) {
		if (decimals < targetPriceDecimals) {
			return amount * (10 ** (targetPriceDecimals - decimals));
		} else if (decimals  > targetPriceDecimals) {
			return amount / (10 ** (targetPriceDecimals - decimals));
		}
		return amount;
	}

	function setPath(bytes memory _path) external onlyOwner {
		path = _path;
	}

	function setQuoter(IQuoter _quoter) external onlyOwner {
		quoter = _quoter;
	}

}