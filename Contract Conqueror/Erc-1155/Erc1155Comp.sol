// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AdvancedERC1155WithRoyaltyAndAuction
/// @notice ERC1155 Token with Royalty and Built-in Auction System — No OpenZeppelin

contract AdvancedERC1155WithRoyaltyAndAuction {
    // ============ ERC1155 Token Logic ============
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _uris;

    // ============ Royalty Logic (EIP-2981) ============
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction; // in basis points (out of 10000)
    }
    mapping(uint256 => RoyaltyInfo) private _royalties;

    // ============ Auction Logic ============
    struct Auction {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool ended;
    }
    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    // ============ Events ============
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 tokenId, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 amount);
    event Refunded(uint256 indexed auctionId, address bidder, uint256 amount);

    // ============ Modifiers ============
    modifier onlyApproved(address from) {
        require(from == msg.sender || _operatorApprovals[from][msg.sender], "Not authorized");
        _;
    }

    modifier onlyBeforeEnd(uint256 auctionId) {
        require(block.timestamp < auctions[auctionId].endTime, "Auction ended");
        _;
    }

    modifier onlyAfterEnd(uint256 auctionId) {
        require(block.timestamp >= auctions[auctionId].endTime, "Auction not ended");
        _;
    }

    modifier notEnded(uint256 auctionId) {
        require(!auctions[auctionId].ended, "Auction already settled");
        _;
    }

    // ============ ERC1155 Core ============
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "Zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Mismatched arrays");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) external onlyApproved(from) {
        require(to != address(0), "Zero address");
        require(_balances[id][from] >= amount, "Insufficient balance");

        _balances[id][from] -= amount;
        _balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external onlyApproved(from) {
        require(to != address(0), "Zero address");
        require(ids.length == amounts.length, "Mismatched arrays");

        for (uint256 i = 0; i < ids.length; i++) {
            require(_balances[ids[i]][from] >= amounts[i], "Insufficient balance");
            _balances[ids[i]][from] -= amounts[i];
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function uri(uint256 id) public view returns (string memory) {
        return _uris[id];
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x2a55205a;
    }

    // ============ Minting with Royalty ============
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory uri_,
        address royaltyReceiver,
        uint96 royaltyFee // out of 10000
    ) external {
        require(to != address(0), "Zero address");
        require(royaltyFee <= 10000, "Too high");

        _balances[id][to] += amount;

        if (bytes(_uris[id]).length == 0) {
            _uris[id] = uri_;
            emit URI(uri_, id);
        }

        if (_royalties[id].receiver == address(0)) {
            _royalties[id] = RoyaltyInfo(royaltyReceiver, royaltyFee);
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        RoyaltyInfo memory royalty = _royalties[tokenId];
        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / 10000;
        return (royalty.receiver, royaltyAmount);
    }

    // ============ Auction Features ============
    function createAuction(uint256 tokenId, uint256 amount, uint256 duration) external returns (uint256) {
        require(_balances[tokenId][msg.sender] >= amount, "Not owner");
        require(duration >= 1 minutes, "Too short");

        _balances[tokenId][msg.sender] -= amount;
        _balances[tokenId][address(this)] += amount;

        auctionCount++;
        auctions[auctionCount] = Auction({
            seller: msg.sender,
            tokenId: tokenId,
            amount: amount,
            endTime: block.timestamp + duration,
            highestBid: 0,
            highestBidder: address(0),
            ended: false
        });

        emit AuctionCreated(auctionCount, msg.sender, tokenId, block.timestamp + duration);
        return auctionCount;
    }

    function bid(uint256 auctionId) external payable onlyBeforeEnd(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(msg.value > auction.highestBid, "Low bid");

        if (auction.highestBidder != address(0)) {
            bids[auctionId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function withdrawBid(uint256 auctionId) external {
        uint256 refund = bids[auctionId][msg.sender];
        require(refund > 0, "No refund");

        bids[auctionId][msg.sender] = 0;
        payable(msg.sender).transfer(refund);

        emit Refunded(auctionId, msg.sender, refund);
    }

    function endAuction(uint256 auctionId) external onlyAfterEnd(auctionId) notEnded(auctionId) {
        Auction storage auction = auctions[auctionId];
        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            _balances[auction.tokenId][address(this)] -= auction.amount;
            _balances[auction.tokenId][auction.highestBidder] += auction.amount;
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            _balances[auction.tokenId][address(this)] -= auction.amount;
            _balances[auction.tokenId][auction.seller] += auction.amount;
        }

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }
}