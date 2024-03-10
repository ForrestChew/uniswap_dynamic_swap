## Regarding Tests

Please run the command:
`forge test --fork-url <ETHEREUM_MAINNET_RPC_URL> --fork-block-number 19402013`
Within the test cases, you will also see console log statements. These indicate how much liquidity the Univ2 & Univ3 pools have of the token being swapped for.
The third console log statement will then show which pool version was used. The pool version used will match up with the pool that has the largest amount of liquidity 
of the token being swapped for.
<br>
![Screenshot 2024-03-10 013022](https://github.com/ForrestChew/uniswap_dynamic_swap/assets/86491214/b02b350d-c29b-4f53-9ee6-b300f44e9c0c)
