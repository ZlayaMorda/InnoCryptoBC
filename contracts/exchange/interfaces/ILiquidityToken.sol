// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ILiquidityToken {

    function stacking(uint256 _amount, address _investor) external;
}