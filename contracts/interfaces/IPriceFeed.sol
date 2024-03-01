// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPriceFeed {
	function fetchPrice(address _token) external returns (uint256);
}