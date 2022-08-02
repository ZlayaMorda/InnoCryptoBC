// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidInno is ERC20 {
    
    constructor() ERC20("LiquidInno", "LI") {
    }
}