// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

abstract contract Constants {
    // Ethereum Mainnet Addresses

    // Uniswap 
    address constant UNI_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant UNI_V3_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant UNI_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant UNI_V2_SWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Tokens
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant INVALID_TOKEN_A = address(1);
    address constant INVALID_TOKEN_B = address(2);

    // Users
    address constant USDC_WHALE = 0xD6153F5af5679a75cC85D8974463545181f48772;
    address constant WETH_WHALE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI_WHALE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
    address constant WBTC_WHALE = 0xA489e9daf10cEd86811d59e4D00ce1b0DEC95f5e;

    // Units
    uint256 constant WETH_1 = 1e18;
    uint256 constant USDC_1000 = 1000e6;
    uint256 constant DAI_1000 = 1000e18;
    uint256 constant WBTC_1 = 1e8;
}