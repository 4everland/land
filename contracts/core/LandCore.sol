// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../interfaces/ILandCore.sol";

contract LandCore is ILandCore {
	address public owner;

	address public guardian;

	bool public paused;

	constructor(address _owner, address _guardian) {
		owner = _owner;
		guardian = _guardian;
		emit GuardianSet(_guardian);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner");
		_;
	}

	function setGuardian(address _guardian) external onlyOwner {
		guardian = _guardian;
		emit GuardianSet(_guardian);
	}

	function setPaused(bool _paused) external {
		require((_paused && msg.sender == guardian) || msg.sender == owner, "Unauthorized");
		paused = _paused;
		if (_paused) {
			emit Paused();
		} else {
			emit Unpaused();
		}
	}

	function transferOwnership(address newOwner) external onlyOwner {
		owner = newOwner;

		emit NewOwnerTransferred(msg.sender, newOwner);
	}

}
