// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "../core/Land.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/ICoin.sol";

contract ETHOracleLand is Land {
	IPriceFeed public priceFeed;
    IPriceFeed public priceFeed4EVER;
    ICoin public token_4ever;


	function initialize(ILandCore _core, IPriceFeed _priceFeed, ICoin[] memory _coins) external initializer {
		__InitCore(_core);
		__Init_Price_Feed(_priceFeed);
		__Init_Coins(_coins);
	}

	function reinitialize( IPriceFeed _4everPriceFeed , ICoin token) external reinitializer(2){
		__Init_4ever_address(token);
		__Init_4ever_Price_Feed(_4everPriceFeed);
	}


	function __Init_Price_Feed(IPriceFeed _priceFeed) internal {
		priceFeed = _priceFeed;
		// check feed is working
		fetchPrice();
	}

	function __Init_4ever_Price_Feed(IPriceFeed _priceFeed) internal {
		priceFeed4EVER = _priceFeed;
		// check feed is working
		fetch4everPrice();
	}

	function __Init_4ever_address(ICoin token) internal {
		token_4ever = token;
	}


	function mintByETH(bytes32 account) external payable whenNotPaused {
		ICoin eth = ICoin(address(0));
		uint256 price = fetchPrice();
		uint256 coinAmount = msg.value * price / 1e18;
		uint256 landAmount = coinAmount * landPerCoin;
		balances[account] += landAmount;
		owner().call{value: msg.value}("");
		deposits[account][eth] += msg.value;
		emit Mint(account, eth, msg.value, coinAmount, landAmount, balances[account]);
	}

    function mintBy4EVER(bytes32 account,uint256 amount)external payable whenNotPaused {
        token_4ever.transferFrom(msg.sender,address(this),amount);
        uint256 price = fetch4everPrice(); // ETH/TOKEN
		uint256 ethAmount = amount * price / 1e18;
		uint256 ethPrice = fetchPrice();
		uint256 coinAmount = ethAmount * ethPrice / 1e18;
        uint256 landAmount = coinAmount * landPerCoin;
        balances[account] += landAmount;
        token_4ever.transfer(owner(),amount);
        deposits[account][token_4ever] += amount;
        emit Mint(account, token_4ever, amount, coinAmount, landAmount, balances[account]);
    }


	function fetchPrice() public returns(uint256) {
		return priceFeed.fetchPrice(address(0));
	}

    function fetch4everPrice() public returns(uint256) {
        return priceFeed4EVER.fetchPrice(address(token_4ever));
    }

	function setPriceFeed(IPriceFeed _priceFeed) external onlyOwner {
		priceFeed = _priceFeed;
	}

    function set4everPriceFeed(IPriceFeed _priceFeed) external onlyOwner {
        priceFeed4EVER = _priceFeed;
    }
}