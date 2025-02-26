// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

interface ICoin {
	function decimals() external view returns(uint8);
}

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


contract LandOwnable {
	ILandCore public LandCore;

	constructor(ILandCore _LandCore) {
		LandCore = _LandCore;
	}

	modifier onlyOwner() {
		require(msg.sender == owner(), "Only owner");
		_;
	}

	modifier onlyGuardian() {
		require(msg.sender == guardian(), "Only guardian");
		_;
	}

	modifier whenNotPaused() {
	    require(!paused(), "paused");
		_;
	}

	function paused() public view returns (bool) {
		return LandCore.paused();
	}

	function owner() public view returns (address) {
		return LandCore.owner();
	}

	function guardian() public view returns (address) {
		return LandCore.guardian();
	}
}



contract CustomPriceFeed is LandOwnable{
    uint32 public constant TWAP_PERIOD = 1800; // 30 minutes
    uint256 public constant Q96 = 2**96;
    address public targetToken;
    IUniswapV3Pool public pool;
	//0xEE83F6873b1d387FccdE7b1d680ff6a7281e8179 ETH / 4EVER

    constructor(ILandCore _core, address token, address _v3Pool) LandOwnable(_core) {
        pool = IUniswapV3Pool(_v3Pool);
        targetToken = token;
    }

    function fetchPrice(address token) public view returns(uint256) {
        require(token == address(targetToken),"ICustomPriceFeed: token is not targetToken");
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = TWAP_PERIOD;
        secondsAgos[1] = 0;
        
        // get tickCumulatives
        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
        
        // calculate time-weighted average tick
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 timeWeightedAverageTick = int24(tickCumulativesDelta / int32(TWAP_PERIOD));
        
        // get token0 and token1
        address token0 = pool.token0();
        address token1 = pool.token1();
        
        // get decimals
        uint8 decimals0 = ICoin(token0).decimals();
        uint8 decimals1 = ICoin(token1).decimals();
        
        // calculate price
        uint256 price = getPriceFromTick(timeWeightedAverageTick, decimals0, decimals1);
        
        // if 4ever is token1, reverse price
        if (address(targetToken) == token1) {
            price = (1e36) / price;
        }
        
        return price;
    }
    
    function getPriceFromTick(
        int24 tick,
        uint8 decimals0,
        uint8 decimals1
    ) internal pure returns (uint256) {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        
        // calculate price = (sqrtPrice * sqrtPrice) * (10^decimals0) / (10^decimals1) / (2^192)
        uint256 price = FullMath.mulDiv(
            uint256(sqrtPriceX96) * uint256(sqrtPriceX96),
            10 ** decimals0,
            uint256(Q96) * uint256(Q96)
        );
        
        // adjust price to 18 decimals
        if (decimals1 < 18) {
            price = price * (10 ** (18 - decimals1));
        } else if (decimals1 > 18) {
            price = price / (10 ** (decimals1 - 18));
        }
        
        return price;
    }
}
