// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDAI is ERC20 {
	constructor() ERC20("DAI StableCoin", "DAI") {
		_mint(msg.sender, 1e40);
	}

	function decimals() public pure override returns(uint8) {
		return 18;
	}
}