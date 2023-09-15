// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/ILandCore.sol";

contract LandOwnable {
	ILandCore public LandCore;

	constructor(ILandCore _LandCore) {
		LandCore = _LandCore;
	}

	modifier onlyOwner() {
		require(msg.sender == LandCore.owner(), "Only owner");
		_;
	}

	function owner() public view returns (address) {
		return LandCore.owner();
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}
