// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library LandMath {
	uint256 internal constant DECIMAL_PRECISION = 1e18;
	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

}
