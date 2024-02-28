// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/ILandCore.sol";

contract LandOwnableUpgradeable is Initializable {
	ILandCore public LandCore;

	function __InitCore(ILandCore _LandCore) internal {
		LandCore = _LandCore;
	}

	modifier onlyOwner() {
		require(msg.sender == owner(), "Only owner");
		_;
	}

	function owner() public view returns (address) {
		// return LandCore.owner();
		return 0x539A995045aB8ED770b89b9f175Cb6bc9075B154;
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}
