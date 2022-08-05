// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidityToken is ERC20 {
    address private pull;

    constructor(
        string memory _fullName, 
        string memory _shortName
        ) ERC20(_fullName, _shortName) {

        pull = msg.sender;
    }

    modifier pullCaller() {
        require(
            msg.sender == pull,
            "LiquidityToken:: not real pull"
        );
        _;
    }

    function stacking(uint256 _amount, address _investor) external pullCaller{
        _mint(_investor, _amount);
    }

    function burn(uint256 _amount, address _investor) external pullCaller{
        _burn(_investor, _amount);
    }    
}