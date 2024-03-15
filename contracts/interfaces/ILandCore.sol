// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ILandCore {
	event GuardianSet(address guardian);
	event NewOwnerTransferred(address oldOwner, address owner);
	event Paused();
	event Unpaused();

	function transferOwnership(address newOwner) external;

	function setGuardian(address _guardian) external;

	function setPaused(bool _paused) external;

	function guardian() external view returns (address);

	function owner() external view returns (address);

	function paused() external view returns (bool);

}
