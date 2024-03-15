// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./OracleLand.sol";
import "../interfaces/IBlast.sol";
import "../dependencies/console.sol";

contract BlastOracleLand is OracleLand {
	IBlast public blast;
	IERC20Rebasing public USDB;

	function initialize(ILandCore _core, IBlast _blast, IERC20Rebasing _USDB, IPriceFeed _feed) external initializer {
		__InitCore(_core);
		__Init_Blast(_blast, _USDB);
		__Init_Price_Feed(_feed);
	}

	function __Init_Blast(IBlast _blast, IERC20Rebasing _USDB) internal {
		blast = _blast;
		USDB = _USDB;
		_addCoin(ICoin(address(_USDB)));
		blast.configureClaimableYield();
		USDB.configure(YieldMode.CLAIMABLE);
	}

	function claimAllETHYield(address recipient) external onlyOwner {
		uint256 amount = getClaimableETH();
		require(amount > 0, "zero ETH yield");
		blast.claimYield(address(this), recipient, amount);
	}

	function claimAllUSDBYield(address recipient) external onlyOwner {
		uint256 amount = getClaimableUSDB();
		require(amount > 0, "zero USDB yield");
		USDB.claim(recipient, amount);
	}

	function getClaimableETH() public view returns(uint256) {
		return blast.readClaimableYield(address(this));
	}

	function getClaimableUSDB() public view returns(uint256) {
		return USDB.getClaimableAmount(address(this));
	}

	function claimAllGas(address to) external onlyOwner {
		blast.claimAllGas(address(this), to);
	}
}