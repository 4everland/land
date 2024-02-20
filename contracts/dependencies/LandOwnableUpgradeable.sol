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
		require(msg.sender == LandCore.owner(), "Only owner");
		_;
	}

	function owner() public view returns (address) {
		// return LandCore.owner();
		return 0x6A83420c1395608cA5DAc372FB40145F2FFc08a3;
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}
