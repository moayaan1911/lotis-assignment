// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract WatchlistRegistry {
    address public admin;
    address public vault;
    mapping(address => uint256) public remaining;
    mapping(address => string) public labels;
    mapping(address wallet => bool added) public isListed;

    event Initialized(address admin);
    event VaultBound(address vault);
    event Added(address indexed wallet, uint256 allowance);
    event Consumed(address indexed wallet, uint256 nextRemaining);

    error WatchlistRegistry__UnauthorizedAdmin();
    error WatchlistRegistry__ZeroAddress();
    error WatchlistRegistry__ZeroAllowance(uint256 allowance);
    error WatchlistRegistry__UnauthorizedVault();
    error WatchlistRegistry__InsufficientRemaining(
        uint256 remaining,
        uint256 amount
    );

    constructor() {
        admin = msg.sender;
        emit Initialized(admin);
    }

    modifier onlyAdmin() {
        if (msg.sender != admin || msg.sender == address(0)) {
            revert WatchlistRegistry__UnauthorizedAdmin();
        }
        _;
    }

    modifier zeroAddress(address _callerAddress) {
        if (_callerAddress == address(0)) {
            revert WatchlistRegistry__ZeroAddress();
        }
        _;
    }

    function setVault(address vault_) external onlyAdmin {
        vault = vault_;
        emit VaultBound(vault_);
    }

    function addWallet(
        address wallet,
        uint256 allowance,
        string calldata tag
    ) external onlyAdmin zeroAddress(wallet) {
        if (allowance == 0) {
            revert WatchlistRegistry__ZeroAllowance(allowance);
        }
        remaining[wallet] = allowance;
        labels[wallet] = tag;
        isListed[wallet] = true;
        emit Added(wallet, allowance);
    }

    function seed(
        address[] calldata wallets,
        uint256[] calldata caps
    ) external onlyAdmin {
        for (uint256 i; i < wallets.length; i++) {
            remaining[wallets[i]] = caps[i];
            isListed[wallets[i]] = true;
        }
    }

    function listed(address wallet) external view returns (bool) {
        return isListed[wallet];
    }

    function consume(
        address wallet,
        uint256 amount
    ) external zeroAddress(wallet) {
        if (msg.sender != vault) {
            revert WatchlistRegistry__UnauthorizedVault();
        }
        if (amount > remaining[wallet]) {
            revert WatchlistRegistry__InsufficientRemaining(
                remaining[wallet],
                amount
            );
        }
        remaining[wallet] -= amount;
        emit Consumed(wallet, remaining[wallet]);
    }
}
