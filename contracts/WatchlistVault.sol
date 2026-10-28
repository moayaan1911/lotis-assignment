// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IWatchlistToken {
    function transfer(address to, uint256 amount) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IWatchlistRegistry {
    function listed(address wallet) external view returns (bool);
    function remaining(address wallet) external view returns (uint256);
    function consume(address wallet, uint256 amount) external;
}

contract WatchlistVault {
    address public admin;
    IWatchlistToken public token;
    IWatchlistRegistry public registry;
    uint256 public recordedDeposits;
    uint256 public totalEthReceived;

    event Deposited(address indexed from, uint256 amount);
    event Pulled(address indexed to, uint256 amount);
    event EthReceived(address indexed sender, uint256 amount, uint256 totalEth);

    error WatchlistVault__AmountCannotBeZero(uint256 amount);
    error WatchlistVault__TransferFailed();
    error WatchlistVault__WalletNotListed();
    error WatchlistVault__NotEnoughBalance();

    constructor(address token_, address registry_) {
        admin = msg.sender;
        token = IWatchlistToken(token_);
        registry = IWatchlistRegistry(registry_);
    }

    function deposit(uint256 amount) external {
        if (amount <= 0) {
            revert WatchlistVault__AmountCannotBeZero(amount);
        }
        bool isSuccess = token.transferFrom(msg.sender, address(this), amount);
        if (!isSuccess) {
            revert WatchlistVault__TransferFailed();
        }
        recordedDeposits += amount;
        emit Deposited(msg.sender, amount);
    }

    receive() external payable {
        totalEthReceived += msg.value;
        emit EthReceived(msg.sender, msg.value, totalEthReceived);
    }

    function withdraw(uint256 amount) external {
        if (!registry.listed(msg.sender)) {
            revert WatchlistVault__WalletNotListed();
        }
        if (amount > registry.remaining(msg.sender)) {
            revert WatchlistVault__NotEnoughBalance();
        }
        token.transfer(msg.sender, amount);
        registry.consume(msg.sender, amount);
        emit Pulled(msg.sender, amount);
    }
}
