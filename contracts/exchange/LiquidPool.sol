// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LiquidityToken.sol";
import "./interfaces/ILiquidityToken.sol";

contract LiquidityPool is Ownable {
    address private token1;
    address private token2;
    address private liquidToken;

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

        LiquidityToken lpToken = new LiquidityToken(_fullName, _shortName, address(this));
        liquidToken = address(lpToken);
    }

    function getliquidToken() external view returns(address){
        return liquidToken;
    }

    function getTokensPair() external view returns(address, address) {
        return (token1, token2);
    }

    function transferToPull(uint256 _token1Sum, uint256 _token2Sum) external {
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
}