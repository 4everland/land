// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./interfaces/ILandCore.sol";

contract LandCore is ILandCore {
	address public owner;
	address public pendingOwner;
	uint256 public ownershipTransferDeadline;

	address public guardian;

	uint256 public constant OWNERSHIP_TRANSFER_DELAY = 86400 * 3;

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

	function commitTransferOwnership(address newOwner) external onlyOwner {
		pendingOwner = newOwner;
		ownershipTransferDeadline = block.timestamp + OWNERSHIP_TRANSFER_DELAY;

		emit NewOwnerCommitted(msg.sender, newOwner, block.timestamp + OWNERSHIP_TRANSFER_DELAY);
	}

	function acceptTransferOwnership() external {
		require(msg.sender == pendingOwner, "Only new owner");
		require(block.timestamp >= ownershipTransferDeadline, "Deadline not passed");

		emit NewOwnerAccepted(owner, msg.sender);

		owner = pendingOwner;
		pendingOwner = address(0);
		ownershipTransferDeadline = 0;
	}

	function revokeTransferOwnership() external onlyOwner {
		emit NewOwnerRevoked(msg.sender, pendingOwner);

		pendingOwner = address(0);
		ownershipTransferDeadline = 0;
	}
}
