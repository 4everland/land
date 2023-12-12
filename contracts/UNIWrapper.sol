// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./dependencies/LandOwnableUpgradeable.sol";
import "./dependencies/console.sol";
import "./interfaces/ILand.sol";
import "./interfaces/IWETH.sol";

contract UNIWrapper is LandOwnableUpgradeable {
	ILand public land;
	ISwapRouter public UNIRouter;
	IWETH public WETH;

	function initialize(ILandCore core, ILand _land, ISwapRouter _UNIRouter, IWETH _WETH) external initializer {
		__InitCore(core);
		land = _land;
		UNIRouter = _UNIRouter;
		WETH = _WETH;
	}

	function mint(ICoin coin, bytes32 account, uint256 amount, uint24 fee) external payable {
		WETH.deposit{value: msg.value}();
		bytes memory path = abi.encodePacked(coin, fee, WETH);
		uint256 w = WETH.balanceOf(address(this));
		WETH.approve(address(UNIRouter), w);
		UNIRouter.exactOutput(
			ISwapRouter.ExactOutputParams({
				path: path,
				recipient: address(this),
				deadline: block.timestamp + 600,
				amountOut: amount,
				amountInMaximum: w
			})
		);
		coin.approve(address(land), amount);
		land.mint(coin, account, amount);
		uint256 value = WETH.balanceOf(address(this));
		WETH.withdraw(value);
		if (value > 0) {
			(bool success,) = msg.sender.call{value: value}("");
			require(success, "UNIWrapper: refund failed");
		}
	}

	receive() external payable {
	}
}