// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IAggregatorV3Interface.sol";
import "../dependencies/LandOwnable.sol";
import "../dependencies/console.sol";
import "../libraries/LandMath.sol";

contract FixedPriceFeed is LandOwnable {
	
	mapping(address => uint256) public prices;

	constructor(ILandCore _core, address _token, uint256 _price) LandOwnable(_core) {
		_setPrice(_token, _price);
	}

	function setPrice(address _token, uint256 _price) external onlyGuardian {
		_setPrice(_token, _price);
	}

	function _setPrice(address _token, uint256 _price) internal {
		prices[_token] = _price;
	}

	function fetchPrice(address _token) public returns (uint256) {
		return prices[_token];
	}
}
