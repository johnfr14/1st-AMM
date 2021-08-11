//SPDX-License-Identifier: Unlicense
  
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityPool_factory.sol";
import "./LiquidityPool.sol";

contract LiquidityPoolFactory is ILiquidityPoolFactory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, uint amount0, uint amount1) external override returns (LiquidityPool pool) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSE");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS"); // single check is sufficient

        pool = new LiquidityPool(tokenA, tokenB);
        pool.add(amount0, amount1);
        getPair[token0][token1] = address(pool);
        getPair[token1][token0] = address(pool); // populate mapping in the reverse direction
        allPairs.push(address(pool));
        emit PairCreated(token0, token1, address(pool), allPairs.length);
    }

    function setFeeTo(address _feeTo) override external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function getPool(address token0_, address token1_) external view returns (address) {
        return getPair[token0_][token1_];
    }
}
