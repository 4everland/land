// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/ILandCore.sol";

contract LandOwnable {
	ILandCore public LandCore;

	constructor(ILandCore _LandCore) {
		LandCore = _LandCore;
	}

	modifier onlyOwner() {
		require(msg.sender == owner(), "Only owner");
		_;
	}

	modifier onlyGuardian() {
		require(msg.sender == guardian(), "Only guardian");
		_;
	}

	modifier whenNotPaused() {
	    require(!paused(), "paused");
		_;
	}

	function paused() public view returns (bool) {
		return LandCore.paused();
	}

	function owner() public view returns (address) {
		return LandCore.owner();
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}
