//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool is ERC20 {
  address public token0;
  address public token1;

  uint private _reserve0;
  uint private _reserve1;

  constructor(address token0_, address token1_) ERC20("LiquidityPool", "John-LP") {
    token0 = token0_;
    token1 = token1_;
  }

  /**
   * Adds liquidity to the pool.
   * 1. Transfer tokens to pool
   * 2. Emit LP tokens
   * 3. Update reserves
   */
  function add(uint amount0, uint amount1) public {

    if (reserve0 == 0 && reserve1 == 0) {
        assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
        assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));
        _mint(msg.sender, amount0 * amount1);
    } else {
        require(amount0 * 100 / _reserve0 == amount1 * 100 / _reserve1, "the ration need to be equal");
        assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
        assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));

        uint rate = amount0 * 100 / _reserve0;
        uint currentSupply = totalSupply();
        uint newSupply = currentSupply * rate / 100;
        _mint(msg.sender, newSupply - currentSupply);
    }

    reserve0 += amount0;
    reserve1 += amount1;
  }

  function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to)
