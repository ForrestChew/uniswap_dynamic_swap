// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap-v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

error InvalidPair();
error ZeroAddress();

event SwapOnce(address token0, address token1, uint256 amountIn, address swapRouter);

contract MainSwapper {

    // Uniswap V3 Variables
    ISwapRouter public uniV3SwapRouter;
    IUniswapV3Factory public uniV3Factory;

    // Uniswap V2 Variables
    IUniswapV2Router02 public uniV2SwapRouter;
    IUniswapV2Factory public uniV2Factory;
    
    constructor(
        address _uniV3SwapRouter, 
        address _uniV3Factory, 
        address _uniV2SwapRouter, 
        address _uniV2Factory
    ) {
        if (
            _uniV3SwapRouter == address(0) || 
            _uniV3Factory == address(0) ||
            _uniV2SwapRouter == address(0) ||
            _uniV2Factory == address(0)
        ) revert ZeroAddress();

        uniV3SwapRouter = ISwapRouter(_uniV3SwapRouter);
        uniV3Factory = IUniswapV3Factory(_uniV3Factory);
        uniV2SwapRouter = IUniswapV2Router02(_uniV2SwapRouter);
        uniV2Factory = IUniswapV2Factory(_uniV2Factory);
    }

    /**
     * @notice         - Swaps token0 to token1 using either a UniswapV2 or UniswapV3 pool.
     *                   The pool used is determined by the pool with the highest liquidity of token1.
     * @param token0   - The token to be swapped from.
     * @param token1   - The token to be swapped to.
     * @param amountIn - The amount of token0 to be swapped for the max amount of token1.
     */
    function swapOnce(address token0, address token1, uint256 amountIn) external {
        if (token0 == address(0) || token1 == address(0)) revert InvalidPair();

        uint24 poolFee = _findOptimalRoute(token0, token1);
        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amountIn
        );
        /// @dev - We know that poolFee will be 0 if the pool is a UniswapV2 pool
        /// since UniswapV2 pools have a fixed fee of 0.3%, and therefore will always return 0 here.
        if (poolFee > 0) {
            _swapOnUniV3(token0, token1, amountIn, poolFee);
            emit SwapOnce(token0, token1, amountIn, address(uniV3SwapRouter));
        } 
        else { 
            _swapOnUniV2(token0, token1, amountIn);
            emit SwapOnce(token0, token1, amountIn, address(uniV2SwapRouter));
        }
    
    }

    /**
     * @notice       - Finds which pool has the highest liquidity of token1, and returns the fee tier of the pool.
     *                 If the pool is a UniswapV2 pool, we know that the fee tier will be 0.3%. So it will return 
     *                 0 from this function. If the pool is a UniswapV3 pool, it will return the actual fee tier 
     *                 of the pool, as it is needed to swap on UniswapV3.
     * @param token0 - The token to be swapped from.
     * @param token1 - The token to be swapped to.
     * @return       - The fee tier of the pool with the highest liquidity of token1.                  
     */
    function _findOptimalRoute(
        address token0,
        address token1
    ) private view returns (uint24) {
        (address uniV2Pool, uint256 token1SupplyV2) = _searchUniV2(token0, token1);
        (
            address uniV3Pool, 
            uint256 token1SupplyV3, 
            uint24 feeTier
        ) = _searchUniV3(token0, token1);

        if (uniV2Pool == address(0) && uniV3Pool == address(0)) revert InvalidPair();

        if (token1SupplyV2 > token1SupplyV3) return 0; /// @dev - We can return 0 here to indicate that the pool is a UniswapV2 pool.
        else if (token1SupplyV2 == token1SupplyV3) 
            /// @dev - 0.3% Is the fixed fee tier for UniswapV2 pools, so if the
            /// liquidity reserve of the dst token is the same, we want to opt for
            /// the pool version with the lowest fee tier.
            return (feeTier > 3000 ? feeTier :  0);
        else return feeTier;
    }

    /**
     * @notice       - Searches for the Uniswap V3 pool with the highest liquidity of token1.
     *                 Since Uniswap V3 pools have different fee tiers, we need to check all pools 
     *                 that have the same pair, but with the four different fee tiers.
     * @param token0 - The token to be swapped from.
     * @param token1 - The token to be swapped to.
     * @return       - The address of the pool with the highest liquidity of token1, the amount of 
     *                 token1 in the pool, and the fee tier of the pool.
     */
    function _searchUniV3(
        address token0,
        address token1
    ) private view returns (address, uint256, uint24) {
        /// @dev - Fee tiers for Uniswap V3 pools. 
        /// Used in conjunction with token addresses to identify pool. 
        uint16[4] memory uniV3FeeTiers = [10000, 3000, 500, 100]; // [1%, 0.3%, 0.05%, 0.01%]
        uint24 finalPoolFee;
        address poolForSwap;
        uint256 highestPoolToken1Bal;

        for (uint8 i = 0; i < 4; i++) {
            address pool = uniV3Factory.getPool(token0, token1, uint24(uniV3FeeTiers[i]));

            if (pool == address(0)) continue;

            uint256 poolToken1Bal = IERC20(token1).balanceOf(pool);

            if (poolToken1Bal > highestPoolToken1Bal) {
                highestPoolToken1Bal = poolToken1Bal;
                poolForSwap = pool;
                finalPoolFee = uniV3FeeTiers[i];
            }
        }

        console.log("Uni V3 Pool Token Out Amount", highestPoolToken1Bal);
        return (poolForSwap, highestPoolToken1Bal, finalPoolFee);
    }

    /**
     * @notice       - Searches for the Uniswap V2 pool with the highest liquidity of token1.
     *                 Since Uniswap V2 pools have a fixed fee tier of 0.3%, we only need to check one pool.
     *                 UniswapV2 factory also has a convenient way to do so.   
     * @param token0 - The token to be swapped from.
     * @param token1 - The token to be swapped to.
     * @return       - The address of the pool with the highest liquidity of token1, and the amount of 
     *                 token1 in the pool.
     */
    function _searchUniV2(
        address token0,
        address token1
    ) private view returns (address, uint256) {
        address poolForSwap = uniV2Factory.getPair(token0, token1);
        uint256 poolToken1Bal = IERC20(token1).balanceOf(poolForSwap);

        console.log("Uni V2 Pool Token Out Amount", poolToken1Bal);
        return (poolForSwap, poolToken1Bal);
    }   

    /**
     * @notice         - Swaps token0 to token1 using a Uniswap V3 pool. Uses the Uniswap 
     *                   V3 router to do so.
     * @param token0   - The token to be swapped from.
     * @param token1   - The token to be swapped to.
     * @param amountIn - The amount of token0 to be swapped for the max amount of token1.
     * @param feeTier  - The fee tier of the pool to be used. Needed as an identifier for the pool.
     */
    function _swapOnUniV3(
        address token0,
        address token1,
        uint256 amountIn,
        uint24 feeTier
    ) private {
        TransferHelper.safeApprove(
            token0,
            address(uniV3SwapRouter),
            amountIn
        );
        ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,  
                sqrtPriceLimitX96: 0
            });
        console.log("Tokens Swapped in Uni V3 Pool");
    }

    /**
     * @notice        - Swaps token0 to token1 using a Uniswap V2 pool. Uses the Uniswap V2 Router.
     * @param token0  - The token to be swapped from.
     * @param token1  - The token to be swapped to.
     * @param amountIn - The amount of token0 to be swapped for the max amount of token1.
     */
    function _swapOnUniV2(
        address token0,
        address token1,
        uint256 amountIn
    ) private {
        TransferHelper.safeApprove(
            token0,
            address(uniV2SwapRouter),
            amountIn
        );
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uniV2SwapRouter.swapExactTokensForTokens(amountIn, 0, path, msg.sender, block.timestamp);
        console.log("Tokens Swapped in Uni V2 Pool");
    }
}
