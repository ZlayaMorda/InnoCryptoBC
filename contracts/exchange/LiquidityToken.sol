// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidityToken is ERC20 {
    address private pull;

    constructor(
        string memory _fullName, 
        string memory _shortName,
        address _pull
        ) ERC20(_fullName, _shortName) {

        pull = _pull;
    }

    function stacking(uint256 _amount, address _investor) external{
        require(
            msg.sender == pull,
            "LiquidityToken:: not real pull"
        );
        _mint(_investor, _amount);
    }    
}