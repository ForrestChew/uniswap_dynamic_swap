// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/MainSwapper.sol";
import "./Constants.t.sol";
import {Test, console2} from "forge-std/Test.sol";

contract MainSwapperTest is Test, Constants {

    MainSwapper swapper;
    IERC20 usdc;

    function setUp() public {
        swapper = new MainSwapper(UNI_V3_SWAP_ROUTER, UNI_V3_FACTORY);
        usdc = IERC20(USDC);
    }

    // function test_MainSwapperDeployment() public {
    //     assertEq(address(swapper.uniV3SwapRouter()), UNI_V3_SWAP_ROUTER);
    //     assertEq(address(swapper.uniV3Factory()), UNI_V3_FACTORY);
    // }

    // function test_findOptimalRoute() public  {
    //     // (address pool, uint48 fee) = swapper.findOptimalRoute(USDC, WETH, USDC_1000);
    //     (address pool, uint48 fee) = swapper.findOptimalRoute(WETH, USDC, WETH_1);
    //     console2.log("Pool: ", pool);
    // } 

    function test_swapOnce() public {
        vm.startPrank(USDC_WHALE);
        usdc.approve(address(swapper), USDC_1000);

        uint256 userUsdcBalBeforeSwap = usdc.balanceOf(USDC_WHALE);
        assertEq(usdc.balanceOf(USDC_WHALE), userUsdcBalBeforeSwap);

        swapper.swapOnce(USDC, WETH, USDC_1000);

        assertEq(usdc.balanceOf(USDC_WHALE), userUsdcBalBeforeSwap - USDC_1000);
    }
}
