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
		return 0x539A995045aB8ED770b89b9f175Cb6bc9075B154;
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}
