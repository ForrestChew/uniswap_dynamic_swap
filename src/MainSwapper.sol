// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap-v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

error InvalidPair();
error ZeroAddress();

contract MainSwapper {

    // Uniswap V3 Variables
    ISwapRouter public uniV3SwapRouter;
    IUniswapV3Factory public uniV3Factory;

    // Uniswap V2 Variables
    
    constructor(address _uniV3SwapRouter, address _uniV3Factory) {
        if (_uniV3SwapRouter == address(0) || _uniV3Factory == address(0)) revert ZeroAddress();

        uniV3SwapRouter = ISwapRouter(_uniV3SwapRouter);
        uniV3Factory = IUniswapV3Factory(_uniV3Factory);
    }

    /** 
     * @param token0 - Address of token to swap for token1
     */  
    function swapOnce(address token0, address token1, uint256 amountIn) external {
        (address swapPool, uint24 poolFee) = findOptimalRoute(token0, token1, amountIn);

        swapUniV3(token0, token1, amountIn, poolFee);
    }

    function findOptimalRoute(
        address _token0,
        address _token1
    ) public view returns (address, uint24) {
        _searchUniV2(_token0, _token1);
        return _searchUniV3(_token0, _token1);
    }

    function _searchUniV3(
        address _token0,
        address _token1
    ) public view returns (address, uint24) {
        /// @dev - Fee tiers for Uniswap V3 pools. 
        /// Used in conjunction with token addresses to identify pool. 
        uint16[4] memory uniV3FeeTiers = [10000, 3000, 500, 100];
        uint24 poolFee;
        address poolForSwap;
        uint256 highestPoolToken1Bal;

        for (uint8 i = 0; i < 4; i++) {
            address pool = uniV3Factory.getPool(_token0, _token1, uint24(uniV3FeeTiers[i]));

            if (pool == address(0)) continue;

            uint256 poolToken1Bal = IERC20(_token1).balanceOf(pool);

            console.log("Pool Bal", poolToken1Bal);
            console.log("Pool Address", pool);

            if (poolToken1Bal > highestPoolToken1Bal) {
                highestPoolToken1Bal = poolToken1Bal;
                poolForSwap = pool;
                poolFee = uniV3FeeTiers[i];
            }
        }

        if (poolForSwap == address(0)) revert InvalidPair();

        return (poolForSwap, poolFee);
    }

    function _searchUniV2(
        address _token0,
        address _token1
    ) public view returns (address, uint24) {
        
    }   

    function swapUniV3(
        address token0,
        address token1,
        uint256 amountIn,
        uint24 feeTier
    ) internal returns (uint256 assetsOut) {
        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(
            token0,
            address(uniV3SwapRouter),
            amountIn
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,  // TODO - Note about slippage
                sqrtPriceLimitX96: 0
            });

        assetsOut = uniV3SwapRouter.exactInputSingle(params);
    }
}
