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
    address[] private stackers;

    address private liquidToken;

    IERC20 private IToken1;
    IERC20 private IToken2;

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

        IToken1 = IERC20(_token1);
        IToken2 = IERC20(_token2);

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

        require(
            IERC20(liquidToken).balanceOf(msg.sender) >= _amountLP,
            "LiquidityPool:: don't have enough LP tokens"
        );

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

        if(IERC20(liquidToken).balanceOf(msg.sender) == 0) {
            _deleteStacker(msg.sender);
        }
    }

    /**
    @dev get token1, calculate num of token2 and stack they in pool
    @param _token1 num of stacking tokens
    */
    function transferThroughToken1(uint256 _token1) external getNullAmount(_token1){
        uint256 balance_1 = _nullToOne(IToken1.balanceOf(address(this)));
        uint256 balance_2 = _nullToOne(IToken2.balanceOf(address(this)));

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
        uint256 balance_1 = _nullToOne(IToken1.balanceOf(address(this)));
        uint256 balance_2 = _nullToOne(IToken2.balanceOf(address(this)));

        uint256 _token1 = _token2 * balance_1 / balance_2;

        require(
            _token1 != 0,
            "LiquidityPool:: too much little sum of invested tokens"
        );

        _transferToPull(_token1, _token2);
    }

    /**
    @dev buy tokens2
    @param _token1 num of token1 to sell
    */
    function buyTokenToken2(uint256 _token1) external getNullAmount(_token1) {
        uint256 balance_1 = _nullToOne(IToken1.balanceOf(address(this)));
        uint256 balance_2 = _nullToOne(IToken2.balanceOf(address(this)));

        uint256 _token2 = ((balance_2 * _token1) * (balance_1 + _token1 + 1)) 
                        / (2 * balance_1 * (balance_1 + _token1) + _token1);

        _transferAndCommission(_token1, _token2);
    }

    /**
    @dev buy tokens1
    @param _token2 num of token2 to sell
    */
    function buyTokenToken1(uint256 _token2) external getNullAmount(_token2) {
        uint256 balance_1 = _nullToOne(IToken1.balanceOf(address(this)));
        uint256 balance_2 = _nullToOne(IToken2.balanceOf(address(this)));

        uint256 _token1 = ((balance_1 * _token2) * (balance_2 + _token2 + 1)) 
                        / (2 * balance_2 * (balance_2 + _token2) + _token2);

        _transferAndCommission(_token2, _token1);
    }

    /**
    @dev get balance of the tokens in pool
    */
    function getPullBalances() external view returns(uint256, uint256) {
        return (IToken1.balanceOf(address(this)), IToken2.balanceOf(address(this)));
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
        return (address(IToken1), address(IToken2));
    }

    /**
    @dev transfer tokens to pool
    @param _token1Sum sum of the first token
    @param _token2Sum sum of the second token
    */
    function _transferToPull(uint256 _token1Sum, uint256 _token2Sum) private {
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

        if(_absentStacker(msg.sender)) {
            stackers.push(msg.sender);
        }
    } 

    /**
    @dev transfer tokens and commission when buy
    @param _tokenSell num of tokens to sell
    @param _tokenBuy num of tokens to buy
    */
    function _transferAndCommission(uint256 _tokenSell, uint256 _tokenBuy) private {
        uint256 commision = (_tokenBuy + _tokenSell) * 3 / 100;

        require(
            IToken1.balanceOf(msg.sender) > 0 && _tokenBuy > 0 && commision > 0,
            "LiquidityPool:: not enough tokens"
        );

        require(
            IToken1.transferFrom(msg.sender, address(this), _tokenSell),
            "LiquidityPool:: transfer from contributer faild"
        );

        require(
                IToken2.transfer(msg.sender, _tokenBuy),
                "LiquidityPool:: transfer faild"
        );

        _divisionCommission(commision);
    }

    /**
    @dev delete stacker from array
    @param _stackerAddress address of the stacker
    */
    function _deleteStacker(address _stackerAddress) private {
        uint256 len = stackers.length;
        if(len == 1) {
            delete stackers[0];
        }
        else {
            for(uint256 i = 0; i < len; i++) {
                if(stackers[i] == _stackerAddress) {
                    stackers[i] = stackers[len - 1];
                    delete stackers[len - 1];
                    break;
                }
            }
        }
    }

    /**
    @dev divide commission between all stackers
    @param _amount commission for the operation
    */
    function _divisionCommission(uint256 _amount) private {
        uint256 sum = _getLPTokenSum();
        IERC20 lpTokenErc = IERC20(liquidToken);
        ILiquidityToken lpToken = ILiquidityToken(liquidToken);

        for(uint256 i = 0; i < stackers.length; i++) {
            uint256 sumToGet = (lpTokenErc.balanceOf(stackers[i]) / sum) * _amount;
            if(sumToGet > 0) {
                lpToken.stacking(sumToGet, stackers[i]);
            }
        }
    }

    /**
    @dev get sum of all LP tokens
    @return sum
    */
    function _getLPTokenSum() private view returns(uint256) {
        uint256 sum = 0;
        for(uint256 i = 0; i < stackers.length; i++) {
            sum += IERC20(liquidToken).balanceOf(stackers[i]);
        }
        return sum;
    }

    /**
    @dev check if stacker absent in the array
    @param _stackerAddress address of the stacker
    @return false if exist, true if not exist
    */
    function _absentStacker(address _stackerAddress) private view returns(bool) {
        for(uint256 i = 0; i < stackers.length; i++) {
            if(stackers[i] == _stackerAddress) {
                return false;
            }
        }
        return true;
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