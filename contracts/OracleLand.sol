// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Land.sol";
import "./interfaces/IPriceFeed.sol";
import "./proxy/AdminWrapper.sol";
import "./dependencies/console.sol";

contract OracleLand is Land, AdminWrapper {
	IPriceFeed public priceFeed;

	function __Init_Price_Feed(IPriceFeed _priceFeed) internal {
		priceFeed = _priceFeed;
	}

	function mintByETH(bytes32 account) external payable {
		require(!paused, "OracleLand: paused");
		ICoin eth = ICoin(address(0));
		uint256 price = fetchPrice();
		uint256 coinAmount = msg.value * price / 1e18;
		uint256 landAmount = coinAmount * landPerCoin;
		balances[account] += landAmount;
		deposits[account][eth] += msg.value;
		emit Mint(account, eth, msg.value, coinAmount, landAmount, balances[account]);
	}

	function fetchPrice() public returns(uint256) {
		return priceFeed.fetchPrice(address(0));
	}

	function setPriceFeed(IPriceFeed _priceFeed) external onlyOwner {
		priceFeed = _priceFeed;
	}

}