// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Land.sol";
import "./interfaces/IPriceFeed.sol";
import "./proxy/AdminWrapper.sol";
import "./dependencies/console.sol";

contract OracleLand is Land, AdminWrapper {
	IPriceFeed public priceFeed;

	function initialize(ILandCore _core, IPriceFeed _priceFeed, ICoin[] memory _coins) external initializer {
		__InitCore(_core);
		priceFeed = _priceFeed;
		for (uint256 i = 0; i < _coins.length; i++) {
			_addCoin(_coins[i]);
		}
	}

	function mintByETH(bytes32 account) external payable {
		require(!paused, "OracleLand: paused");
		ICoin eth = ICoin(address(0));
		uint256 price = priceFeed.fetchPrice();
		uint256 coinAmount = msg.value * price / 1e18;
		uint256 landAmount = coinAmount * landPerCoin;
		balances[account] += landAmount;
		deposits[account][eth] += msg.value;
		emit Mint(account, eth, msg.value, coinAmount, landAmount, balances[account]);
	}

	function setPriceFeed(IPriceFeed _priceFeed) external onlyOwner {
		priceFeed = _priceFeed;
	}

	function upgradeWith(IPriceFeed _priceFeed) external onlyAdmin {
		priceFeed = _priceFeed;
	}

}