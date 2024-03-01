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

	function owner() public view returns (address) {
		return 0x6A83420c1395608cA5DAc372FB40145F2FFc08a3;
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}
