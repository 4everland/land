// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "../dependencies/LandOwnableUpgradeable.sol";
import "../interfaces/ILand.sol";

contract Land is ILand, LandOwnableUpgradeable {
	using EnumerableMap for EnumerableMap.AddressToUintMap;
	uint64 public constant landPerCoin = 1e6;
	uint8 public constant targetPriceDecimals = 18;
	EnumerableMap.AddressToUintMap internal coins;
	mapping(bytes32 => uint256) internal balances;
	mapping(bytes32 => mapping(ICoin => uint256)) public deposits;

	function __Init_Coins(ICoin[] memory _coins) internal {
		for (uint64 i = 0; i < _coins.length; i++) {
			_addCoin(_coins[i]);
		}
	}

	function mint(ICoin coin, bytes32 account, uint256 amount) external whenNotPaused {
		require(coinExists(coin), "Land: nonexistent coin");
		(bool success1,) = address(coin).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
		require(success1, "Land: transfer from failed");
		uint256 coinAmount = formatValue(coin, amount);
		uint256 landAmount = coinAmount * landPerCoin;
		balances[account] += landAmount;
		deposits[account][coin] += amount;
		(bool success2,) = address(coin).call(abi.encodeWithSignature("transfer(address,uint256)", owner(), amount));
		require(success2, "Land: transfer failed");
		emit Mint(account, coin, amount, coinAmount, landAmount, balances[account]);
	}

	function addCoin(ICoin coin) external onlyGuardian {
		_addCoin(coin);
	}

	function _addCoin(ICoin coin) internal {
		require(!coinExists(coin), "Land: coin exists");
		uint8 decimals = coin.decimals();
		coins.set(address(coin), decimals);
		emit AddCoin(coin);
	}

	function removeCoin(ICoin coin) external onlyGuardian {
		_removeCoin(coin);
	}

	function _removeCoin(ICoin coin) internal {
		require(coinExists(coin), "Land: nonexistent coin");
		coins.remove(address(coin));
		emit RemoveCoin(coin);
	}

	function coinLength() public view returns(uint256) {
		return coins.length();
	}

	function coinAt(uint256 i) public view returns(address, uint256) {
		return coins.at(i);
	}

	function coinExists(ICoin coin) public view returns(bool) {
		return coins.contains(address(coin));
	}

	function decimalsOf(ICoin coin) public view returns(uint8) {
		return uint8(coins.get(address(coin)));
	}

	function balanceOf(bytes32 to) public view returns(uint256) {
		return balances[to];
	}

	function formatValue(ICoin coin, uint256 amount) public view returns(uint256) {
		uint8 decimals = decimalsOf(coin);
		if (decimals < targetPriceDecimals) {
			return amount * (10 ** (targetPriceDecimals - decimals));
		} else if (decimals  > targetPriceDecimals) {
			return amount / (10 ** (targetPriceDecimals - decimals));
		}
		return amount;
	}

	function withdraw(ICoin coin, address to, uint256 amount) external onlyOwner {
		if (address(coin) != address(0)) {
			coin.transfer(to, amount);
		} else {
			(bool success,) = to.call{value: amount}("");
			require(success, "Land: tranfer failed");
		}
		emit WithdrawnCoin(coin, to, amount);
	}

}