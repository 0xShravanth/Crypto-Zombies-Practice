// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MyToken - Basic ERC-20 Token Implementation
contract MyToken {
    // Mapping from address to balance
    mapping(address => uint256) private _balances;

    // Mapping from owner => spender => allowance
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    /// @notice Sets name, symbol, and decimals at deployment
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals)));
    }

    /// @notice Returns total tokens created
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns token balance of an account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice Transfer tokens from sender to another address
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(_balances[msg.sender] >= amount, "Not enough balance");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Approve a spender to spend tokens
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns how much spender can use from owner’s account
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Transfer from one account to another (using allowance)
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Not enough allowance");
        require(_balances[from] >= amount, "Not enough balance");

        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /// @dev Internal mint function
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Invalid address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev Internal burn function
    function _burn(address from, uint256 amount) internal {
        require(_balances[from] >= amount, "Not enough to burn");
        _totalSupply -= amount;
        _balances[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    /// ERC-20 Events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
