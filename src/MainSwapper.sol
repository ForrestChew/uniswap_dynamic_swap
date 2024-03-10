// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap-v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap-v3-periphery/contracts/libraries/TransferHelper.sol";
import "forge-std/console.sol";

contract Swapper {


    constructor(address uniV2Factory, address uniV3Factory, address _swapRouter) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    function swapOnce(address token0, address token1, uint256 amountIn) external {
        
    }

    function findOptimalRoute(
        address _token0,
        address _token1,
        uint256 _amountIn
    ) external view returns (address[] memory path) {

    }


    function swapUniV3(
        uint256 _collateralAmtIn,
        address _lendToken,
        address _colToken
    ) external returns (uint256 lendAssetOut) {
        TransferHelper.safeTransferFrom(
            _colToken,
            msg.sender,
            address(this),
            _collateralAmtIn
        );
        TransferHelper.safeApprove(
            _colToken,
            address(swapRouter),
            _collateralAmtIn
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _colToken,
                tokenOut: _lendToken,
                fee: 10000,
                recipient: msg.sender,
                amountIn: _collateralAmtIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        lendAssetOut = swapRouter.exactInputSingle(params);
    }
}
