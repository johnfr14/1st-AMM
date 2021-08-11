//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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

    if (_reserve0 == 0 && _reserve1 == 0) {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        _mint(msg.sender, amount0 * amount1);
    } else {
        require(amount0 * 100 / _reserve0 == amount1 * 100 / _reserve1, "the ration need to be equal");
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        uint rate = amount0 * 100 / _reserve0;
        uint currentSupply = totalSupply();         
        uint newSupply = currentSupply * rate / 100;
        _mint(msg.sender, newSupply - currentSupply);
    }

    _reserve0 += amount0;
    _reserve1 += amount1;
  }

  function remove(uint liquidity) public {

    transfer(address(this), liquidity);

    uint currentSupply = totalSupply();
    uint amount0 = liquidity * _reserve0 / currentSupply;
    uint amount1 = liquidity * _reserve1 / currentSupply;
    

    _burn(address(this), liquidity);

    _reserve0 = _reserve0 - amount0;
    _reserve1 = _reserve1 - amount1;

    IERC20(token0).transfer(msg.sender, amount0);
    IERC20(token1).transfer(msg.sender, amount1);
  }


  function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint reserve0_, uint reserve1_) {
    uint newReserve0;
    uint newReserve1;
    uint k = _reserve0 * _reserve1;

    // x (2) * y (10) = k (20)
    // swap => x + 1
    // newReserve0 = 1 + 2;
    // newReserve1 = 20 / 3;
    // amountOut = 10 - 6.666666;

    // x(3) * y(6.66667) = k (20)

    if (fromToken == token0) {
      newReserve0 = amountIn + _reserve0;
      newReserve1 = k / newReserve0;
      amountOut = _reserve1 - newReserve1;
    } else {
      newReserve1 = amountIn + _reserve1;
      newReserve0 = k / newReserve1;
      amountOut = _reserve0 - newReserve0;
    }

    reserve0_ = newReserve0;
    reserve1_ = newReserve1;

    return (amountOut, reserve0_, reserve1_);
  }

  function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0, "Amount invalid");
    require(fromToken == token0 || fromToken == token1, "From token invalid");
    require(toToken == token0 || toToken == token1, "To token invalid");
    require(fromToken != toToken, "From and to tokens should not match");

    (uint amountOut, uint newReserve0, uint newReserve1) = getAmountOut(amountIn, fromToken);

    require(amountOut >= minAmountOut, "Slipped... on a banana");

    _reserve0 = newReserve0;
    _reserve1 = newReserve1;

    IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
    IERC20(toToken).transfer(to, amountOut);
  }

}
