// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract WatchlistToken {
    string public name = "Watchlist USD";
    string public symbol = "wUSD";
    uint8 public decimals = 18;
    address admin;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address from, address to, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);

    error WatchlistToken__Unauthorized();
    error WatchlistToken__ZeroAddress();
    error WatchlistToken__NotEnoughBalance();
    error WatchlistToken__InsufficientAllowance(
        uint256 allowance,
        uint256 amount
    );

    modifier onlyAdmin() {
        if (msg.sender != admin || msg.sender == address(0)) {
            revert WatchlistToken__Unauthorized();
        }
        _;
    }

    constructor() {
        admin = msg.sender;
        uint256 minted = 1_000_000 ether;
        balanceOf[admin] = minted;
        totalSupply = minted;
        emit Transfer(address(0), admin, minted);
    }

    function mint(address to, uint256 amount) external onlyAdmin {
        if (to == address(0)) {
            revert WatchlistToken__ZeroAddress();
        }
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external {
        if (balanceOf[msg.sender] < amount) {
            revert WatchlistToken__NotEnoughBalance();
        }
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed < amount) {
            revert WatchlistToken__InsufficientAllowance(allowed, amount);
        }
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
            emit Approval(from, msg.sender, allowed - amount);
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
