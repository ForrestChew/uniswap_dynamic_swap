// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/MainSwapper.sol";
import "./Constants.t.sol";
import {Test, console2} from "forge-std/Test.sol";

contract MainSwapperTest is Test, Constants {

    MainSwapper swapper;

    IERC20 weth;
    IERC20 usdc;
    IERC20 dai;
    IERC20 wbtc;

    function setUp() public {
        swapper = new MainSwapper(
            UNI_V3_SWAP_ROUTER, 
            UNI_V3_FACTORY,
            UNI_V2_SWAP_ROUTER,
            UNI_V2_FACTORY
        );
        weth = IERC20(WETH);
        usdc = IERC20(USDC);
        dai = IERC20(DAI);
        wbtc = IERC20(WBTC);
    }

    function test_swapOnce_USDC_For_WETH() public {
        testSwapOnce(USDC, WETH, USDC_WHALE, USDC_1000);
    }

    function test_swapOnce_WBTC_For_WETH() public {
        testSwapOnce(WBTC, WETH, WBTC_WHALE, WBTC_1);
    }

    function test_swapOnce_DAI_For_WBTC() public {
        testSwapOnce(DAI, WBTC, DAI_WHALE, DAI_1000);
    }

    function test_swapOnce_DAI_For_USDC() public {
        testSwapOnce(DAI, USDC, DAI_WHALE, DAI_1000);
    }

    function testSwapOnce(address tokenIn, address tokenOut, address whale, uint256 amountIn) internal {
        vm.startPrank(whale);
        IERC20(tokenIn).approve(address(swapper), amountIn);

        uint256 userBalBeforeSwap = IERC20(tokenIn).balanceOf(whale);
        assertEq(IERC20(tokenIn).balanceOf(whale), userBalBeforeSwap);

        swapper.swapOnce(tokenIn, tokenOut, amountIn);

        assertEq(IERC20(tokenIn).balanceOf(whale), userBalBeforeSwap - amountIn);
    }
}
