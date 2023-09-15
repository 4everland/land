// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
	constructor() ERC20("USD StableCoin", "USDC") {
		_mint(msg.sender, 1e30);
	}

	function decimals() public pure override returns(uint8) {
		return 6;
	}
}