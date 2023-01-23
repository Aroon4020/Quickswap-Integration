// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;
import './libraries/LiquidityAmounts.sol';
import './libraries/TickMath.sol';
import './interfaces/IERC20Minimal.sol';
import './interfaces/IAlgebraFactory.sol';
import './interfaces/IAlgebraPool.sol';


contract V3{
    
    IAlgebraFactory public factory;
    IAlgebraPool public pool;
    constructor(address _factory){
        factory = IAlgebraFactory(_factory);
    }
    
    function create(
        address token0,
        address token1,
        uint160 sqrtPriceX96
    ) external payable returns (address _pool) {

        _pool = IAlgebraFactory(factory).poolByPair(token0, token1);

        if (_pool == address(0)) {
            _pool = IAlgebraFactory(factory).createPool(token0, token1);
            IAlgebraPool(_pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IAlgebraPool(_pool).globalState();
            if (sqrtPriceX96Existing == 0) {
                IAlgebraPool(_pool).initialize(sqrtPriceX96);
            }
        }
        pool = IAlgebraPool(_pool);
    }

     function addLiquidity(
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1        
    ) external {
        
        (,int160 sqrtRatioX96, , , , ,) = IAlgebraPool(pool).globalState();
        
        uint128 liquidity =
            LiquidityAmounts.getLiquidityForAmounts(
                uint160(sqrtRatioX96),
                TickMath.getSqrtRatioAtTick(lowerTick),
                TickMath.getSqrtRatioAtTick(upperTick),
                amount0,
                amount1
            );
            
            IERC20Minimal(pool.token0()).transferFrom(
                msg.sender,
                address(this),
                uint256(amount0)
            );
            IERC20Minimal(pool.token1()).transferFrom(
                msg.sender,
                address(this),
                uint256(amount1)
            );
            
        pool.mint(address(this),address(this), lowerTick, upperTick, liquidity, abi.encode(address(this)));
    }

    function burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 _amount0,
        uint256 _amount1
    ) external returns (uint256 amount0, uint256 amount1) {
        (,int160 sqrtRatioX96, , , , ,) = pool.globalState();

        uint128 liquidity =
            LiquidityAmounts.getLiquidityForAmounts(
                uint160(sqrtRatioX96),
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                _amount0,
                _amount1
            );
        (amount0, amount1) = pool.burn(tickLower, tickUpper, liquidity);
        if (amount0 > 0 || amount1 > 0) {
            (amount0, amount0) = pool.collect(msg.sender, tickLower, tickUpper, uint128(amount0), uint128(amount1));
        }
    }

    function swap(
        bool zeroForOne,
        bool isReflectionary,
        int256 amountSpecified

    ) external {        
        uint160 sqrtPriceLimitX96 = (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1);
        if(isReflectionary)
            pool.swapSupportingFeeOnInputTokens(address(this),address(this), zeroForOne, amountSpecified, sqrtPriceLimitX96, abi.encode(msg.sender));
        else
            pool.swap(address(this), zeroForOne, amountSpecified, sqrtPriceLimitX96, abi.encode(msg.sender));
    }

    function collect(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = pool.collect(msg.sender, tickLower, tickUpper, amount0Requested, amount1Requested);
    }

    function algebraMintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        if (amount0Owed > 0)
            IERC20Minimal(IAlgebraPool(pool).token0()).transferFrom(
                abi.decode(data, (address)),
                msg.sender,
                amount0Owed
            );

        if (amount1Owed > 0)
            IERC20Minimal(IAlgebraPool(pool).token1()).transferFrom(
                abi.decode(data, (address)),
                msg.sender,
                amount1Owed
            );
    }

    function algebraSwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) external {
        if (amount0 > 0) {
            IERC20Minimal(IAlgebraPool(msg.sender).token0()).transferFrom(
                abi.decode(data, (address)),
                msg.sender,
                uint256(amount0)
            );
        } else if (amount1 > 0) {
            IERC20Minimal(IAlgebraPool(msg.sender).token1()).transferFrom(
                abi.decode(data, (address)),
                msg.sender,
                uint256(amount1)
            );
        }
    }
}