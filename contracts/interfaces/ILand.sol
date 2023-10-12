// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ICoin.sol";

interface ILand {
	event AddCoin(ICoin coin);

	event RemoveCoin(ICoin coin);

	event WithdrawnCoin(ICoin coin, address to, uint256 amount);

	event Mint(bytes32 account, ICoin coin, uint256 value, uint256 coinAmount, uint256 landAmount);

	function addCoin(ICoin coin) external;

	function coinExists(ICoin coin) external view returns(bool);

	function decimalsOf(ICoin coin) external view returns(uint8);

	function balanceOf(bytes32 account) external view returns(uint256);

	function formatValue(ICoin coin, uint256 amount) external view returns(uint256);

	function withdraw(ICoin coin, address to, uint256 amount) external;
}