// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./Land.sol";
import "./interfaces/IPriceFeed.sol";
import "./proxy/AdminWrapper.sol";
import "./dependencies/console.sol";

contract FixedLand is Land, AdminWrapper {

	function initialize(ILandCore _core, ICoin[] memory _coins) external initializer {
		__InitCore(_core);
		for (uint256 i = 0; i < _coins.length; i++) {
			_addCoin(_coins[i]);
		}
	}

	function mintByETH(bytes32 account) external payable {
		require(!paused, "FixedLand: paused");
		ICoin WETH = ICoin(0x5300000000000000000000000000000000000004);
		uint256 value = 2300e18 * msg.value / 1e18;
		uint256 coinAmount = formatValue(value, 18);
		uint256 landAmount = coinAmount * landPerCoin;
		balances[account] += landAmount;
		deposits[account][WETH] += msg.value;
		emit Mint(account, WETH, msg.value, coinAmount, landAmount, balances[account]);
	}

	function formatValue(uint256 amount, uint8 decimals) public pure returns(uint256) {
		if (decimals < targetPriceDecimals) {
			return amount * (10 ** (targetPriceDecimals - decimals));
		} else if (decimals  > targetPriceDecimals) {
			return amount / (10 ** (targetPriceDecimals - decimals));
		}
		return amount;
	}

}