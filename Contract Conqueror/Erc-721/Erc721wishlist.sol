// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title WhitelistNFT
/// @notice NFT contract with whitelist-based minting
contract WhitelistNFT {
    string public name;
    string public symbol;
    string private baseURI;
    uint256 public totalSupply;
    address public owner;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private whitelist;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Whitelisted(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        owner = msg.sender;
    }

    /// @notice Adds an address to the whitelist
    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
        emit Whitelisted(user);
    }

    /// @notice Removes an address from the whitelist
    function removeFromWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
        emit RemovedFromWhitelist(user);
    }

    /// @notice Check if an address is whitelisted
    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }

    /// @notice Mint a token (only for whitelisted users)
    function safeMint() public onlyWhitelisted {
        require(msg.sender != address(0), "Zero address");

        uint256 tokenId = totalSupply + 1;
        _balances[msg.sender] += 1;
        _owners[tokenId] = msg.sender;
        totalSupply = tokenId;

        emit Transfer(address(0), msg.sender, tokenId);
    }

    /// @notice Returns balance of an owner
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Zero address");
        return _balances[_owner];
    }

    /// @notice Returns owner of a token
    function ownerOf(uint256 tokenId) public view returns (address) {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "Token doesn't exist");
        return _owner;
    }

    /// @notice Returns token URI for a given tokenId
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    /// @notice Set base URI
    function setBaseURI(string memory _base) public onlyOwner {
        baseURI = _base;
    }

    /// @dev Converts uint to string (for tokenURI)
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint256 temp = _i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory bStr = new bytes(digits);
        while (_i != 0) {
            digits -= 1;
            bStr[digits] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        str = string(bStr);
    }
}
