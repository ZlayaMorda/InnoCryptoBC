// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
LP token for pools
users get it instead of invested tokens in pool
may burn it and get pool tokens back
*/
contract LiquidityToken is ERC20 {
    address private pool;

    /**
    @dev set address of valid pool
    @param _fullName full name of the new LP token
    @param _shortName short name of the new LP token
    */
    constructor(
        string memory _fullName, 
        string memory _shortName
        ) ERC20(_fullName, _shortName) {

        pool = msg.sender;
    }

    /**
    @dev Check if sender is valid pool
    */
    modifier poolCaller() {
        require(
            msg.sender == pool,
            "LiquidityToken:: not real pool"
        );
        _;
    }

    /**
    @dev minting new LP tokens for user
    @param _amount num of the tokens
    @param _investor user get tokens
    */
    function stacking(uint256 _amount, address _investor) external poolCaller{
        _mint(_investor, _amount);
    }

    /**
    @dev burn user LP tokens
    @param _amount num of the tokens
    @param _investor user's address
    */
    function burn(uint256 _amount, address _investor) external poolCaller{
        _burn(_investor, _amount);
    }    
}
