// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LiquidityToken.sol";
import "./interfaces/ILiquidityToken.sol";

/**
Create LP token
functions for stacke, withdraw, exchange tokens
*/
contract LiquidityPool is Ownable {
    address private token1;
    address private token2;
    address private liquidToken;

    /**
    @dev create LP token, set exchange tokens addresses
    @param _token1 first token address
    @param _token2 second token address
    @param _fullName full name of the new LP token
    @param _shortName short name of the new LP token
    */
    constructor (
        address _token1, 
        address _token2,
        string memory _fullName, 
        string memory _shortName
        ) {
        require(
            _token1 != address(0) && _token2 != address(0),
            "LiquidityPool:: null setted token address"
        );
        token1 = _token1;
        token2 = _token2;

        LiquidityToken lpToken = new LiquidityToken(_fullName, _shortName);
        liquidToken = address(lpToken);
    }

    /**
    @dev the amount must be not null
    @param _amount amount to check
    */
    modifier getNullAmount(uint256 _amount) {
        require(
            _amount != 0,
            "LiquidityPool:: get null amount"
        );
        _;
    }

    /**
    @dev withdraw tokens from pull and burn LP tokens
    @param _amountLP amount of the LP tokens
    */
    function withdraw(uint256 _amountLP) external getNullAmount(_amountLP){
        IERC20 IToken1 = IERC20(token1);
        IERC20 IToken2 = IERC20(token2);

        uint256 balance_1 = IToken1.balanceOf(address(this));
        uint256 balance_2 = IToken2.balanceOf(address(this));

        require(
            balance_1 != 0 || balance_2 != 0,
            "LiquidityPool:: pull is free"
        );

        uint256 sum_1 = (balance_1 / (balance_1 + balance_2)) * _amountLP;
        uint256 sum_2 = (balance_2 / (balance_2 + balance_1)) * _amountLP;

        require(
            sum_1 != 0 && sum_2 != 0,
            "LiquidityPool:: sums try to withdraw are 0"
        );

        ILiquidityToken(liquidToken).burn(_amountLP, msg.sender);

        if(sum_1 != 0) {
            require(
                IToken1.transfer(msg.sender, sum_1),
                "LiquidityPool:: transfer faild"
            );
        }
        if(sum_2 != 0) {
            require(
                IToken2.transfer(msg.sender, sum_2),
                "LiquidityPool:: transfer faild"
            );
        }

    }

    /**
    @dev get token1, calculate num of token2 and stack they in pool
    @param _token1 num of stacking tokens
    */
    function transferThroughToken1(uint256 _token1) external getNullAmount(_token1){
        uint256 balance_1 = _nullToOne(IERC20(token1).balanceOf(address(this)));
        uint256 balance_2 = _nullToOne(IERC20(token2).balanceOf(address(this)));

        uint256 _token2 = _token1 * balance_2 / balance_1;

        require(
            _token2 != 0,
            "LiquidityPool:: too much little sum of invested tokens"
        );

        _transferToPull(_token1, _token2);
    }

    /**
    @dev get token2, calculate num of token1 and stack they in pool
    @param _token2 num of stacking tokens
    */
    function transferThroughToken2(uint256 _token2) external getNullAmount(_token2){
        uint256 balance_1 = _nullToOne(IERC20(token1).balanceOf(address(this)));
        uint256 balance_2 = _nullToOne(IERC20(token2).balanceOf(address(this)));

        uint256 _token1 = _token2 * balance_1 / balance_2;

        require(
            _token1 != 0,
            "LiquidityPool:: too much little sum of invested tokens"
        );

        _transferToPull(_token1, _token2);
    }

    /**
    @dev get balance of the tokens in pool
    */
    function getPullBalances() external view returns(uint256, uint256) {
        return (IERC20(token1).balanceOf(address(this)), IERC20(token2).balanceOf(address(this)));
    }

    /**
    @dev get address of the LP token
    */
    function getliquidToken() external view returns(address){
        return liquidToken;
    }

    /**
    @dev get addresses of tokens in the pool
    */
    function getTokensPair() external view returns(address, address) {
        return (token1, token2);
    }

    /**
    @dev transfer tokens to pool
    @param _token1Sum sum of the first token
    @param _token2Sum sum of the second token
    */
    function _transferToPull(uint256 _token1Sum, uint256 _token2Sum) private {
        IERC20 IToken1 = IERC20(token1);
        IERC20 IToken2 = IERC20(token2);
        require(
            IToken1.balanceOf(msg.sender) >= _token1Sum &&
            IToken2.balanceOf(msg.sender) >= _token2Sum,
            "LiquidityPool:: don't have enough tokens"
        );

        require(
            IToken1.transferFrom(msg.sender, address(this), _token1Sum),
            "LiquidityPool:: transfer from contributer faild"
        );

        require(
            IToken2.transferFrom(msg.sender, address(this), _token2Sum),
            "LiquidityPool:: transfer from contributer faild"
        );

        ILiquidityToken(liquidToken).stacking(_token1Sum + _token2Sum, msg.sender);
    } 

    /**
    @dev check if sum null and change it to 1
    @param _sum sum to check
    @return 1 or _sum
    */
    function _nullToOne(uint256 _sum) private pure returns(uint256) {
        if(_sum == 0) {
            return 1;
        }
        else {
            return _sum;
        }
    }
}