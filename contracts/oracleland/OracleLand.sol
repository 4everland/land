// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "../core/Land.sol";
import "../interfaces/IPriceFeed.sol";

contract OracleLand is Land {
	IPriceFeed public priceFeed;

	function initialize(ILandCore _core, IPriceFeed _priceFeed, ICoin[] memory _coins) external initializer {
		__InitCore(_core);
		__Init_Price_Feed(_priceFeed);
		__Init_Coins(_coins);
	}

	function __Init_Price_Feed(IPriceFeed _priceFeed) internal {
		priceFeed = _priceFeed;
		// check feed is working
		fetchPrice();
	}

	function mintByETH(bytes32 account) external payable whenNotPaused {
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