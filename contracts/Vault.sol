// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import {Errors} from "./libraries/Errors.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './System.sol';
import 'hardhat/console.sol';

contract Vault {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    System public system;

    event TokensDeposited(address account, address token, uint256 amount);
    event TokenWithdrawn(address account, address token, uint256 amount);

    constructor(address _system) {
        system = System(_system);
    }

    mapping(address => mapping(address => uint256)) public userTokenBalance;
    mapping(address => mapping(address => uint256)) public userTokenBalanceInOrder;

    function deposit(address token, uint256 amount) external {
        if (amount == 0) revert('ZeroAmt'); // Errors.ZeroAmt();
        userTokenBalance[msg.sender][token] = userTokenBalance[msg.sender][token].add(amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit TokensDeposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        if (amount == 0) revert('ZeroAmt'); // Errors.ZeroAmt();
        userTokenBalance[msg.sender][token] = userTokenBalance[msg.sender][token].sub(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, token, amount);
    }

    function getBalance(address token) public view returns (uint256) {
        return userTokenBalance[msg.sender][token];
    }

    // Update sellers asset details only on LIMITSELL
    function lockToken(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        // console.log('Locking %s %s for %s', amount, ERC20(token).symbol(), account);
        userTokenBalanceInOrder[account][token] = userTokenBalanceInOrder[account][token].add(amount);
    }

    //Update data on order execution
    function increaseBalance(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalance[account][token] = userTokenBalance[account][token].add(amount);
    }

    function decreaseBalance(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalance[account][token] = userTokenBalance[account][token].sub(amount);
    }

    // Update sellers asset details only on LIMITSELL
    function unlockToken(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalanceInOrder[account][token] = userTokenBalanceInOrder[account][token].sub(amount);
    }

    modifier onlyExchanger() {
        if(msg.sender != address(system.exchange())) revert('NotAuthorized'); // Errors.NotAuthorized();
        _;
    }
}
