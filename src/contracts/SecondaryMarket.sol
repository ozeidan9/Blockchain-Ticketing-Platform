// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./PurchaseToken.sol";
import "./TicketNFT.sol";
import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IERC20.sol";

contract SecondaryMarket is ISecondaryMarket {
    uint256 public constant FEE_PERCENTAGE = 5;
    IERC20 public purchaseToken;
    ITicketNFT private ticketNFT;
   
    struct SaleDetails {
        address seller;
        uint256 price;
        bool isListed; 
    }
    struct BidDetails { 
        string name; 
        address bidder;
        uint256 amount; 
    }

    mapping(address => mapping(uint256 => BidDetails)) public ticketBids; 
    mapping(address => SaleDetails) public List;

    constructor(PurchaseToken _purchaseToken) {
        purchaseToken = IERC20(address((_purchaseToken)));
    }

   function listTicket(
    address ticketCollection,
    uint256 ticketID,
    uint256 price
    ) external override {
        require(
            !ITicketNFT(ticketCollection).isExpiredOrUsed(ticketID),
            "Ticket is expired or already used"
        );
        require(
            ITicketNFT(ticketCollection).holderOf(ticketID) == msg.sender, 
            "Caller is not ticket owner"
        );
        
        
        ITicketNFT(ticketCollection).transferFrom(msg.sender, address(this), ticketID);
        ITicketNFT(ticketCollection).approve(address(this), ticketID);

        List[ticketCollection] = SaleDetails({ 
            seller: msg.sender, 
            price: price, 
            isListed: true
        }); 
        ticketBids[ticketCollection][ticketID] = BidDetails({ 
            name: "", 
            bidder: address(0),
            amount: price 
        });

        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }


    function submitBid(
        address ticketCollection,
        uint256 ticketID,
        uint256 bidAmount,
        string calldata name
    ) external override {
        SaleDetails storage listing = List[ticketCollection];    
        
        require(
            bidAmount > ticketBids[ticketCollection][ticketID].amount,
            "BidDetails must be higher than the current highest"
        );
        require(listing.isListed, "Ticket not listed"); 
        
        BidDetails memory currentHighestBid = ticketBids[ticketCollection][ticketID]; 
        if (currentHighestBid.amount > 0 && currentHighestBid.bidder != address(0)) { 
            purchaseToken.transfer(currentHighestBid.bidder, currentHighestBid.amount); 
        }

        purchaseToken.transferFrom(msg.sender, address(this), bidAmount); 
        purchaseToken.approve(address(this), bidAmount);
    
        ticketBids[ticketCollection][ticketID] = BidDetails(name, msg.sender, bidAmount);
        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }

    function acceptBid(address ticketCollection, uint256 ticketID) external override {

        SaleDetails memory listing = List[ticketCollection]; 
        require(listing.seller == msg.sender, "Only seller can accept bid");
        require(listing.isListed, "Ticket not listed"); 

        BidDetails memory bid = ticketBids[ticketCollection][ticketID];

        uint256 fee = calculateFee(bid.amount);
        purchaseToken.transfer(ITicketNFT(ticketCollection).creator(), fee);
        purchaseToken.transfer(listing.seller, bid.amount - fee);
        
        ITicketNFT(ticketCollection).updateHolderName(ticketID, bid.name); 
        ITicketNFT(ticketCollection).transferFrom(address(this), bid.bidder, ticketID);
        emit BidAccepted(bid.bidder, ticketCollection, ticketID, bid.amount, "");
       
        delete ticketBids[ticketCollection][ticketID];
        delete List[ticketCollection];
    }

    function delistTicket(address ticketCollection, uint256 ticketID) external override {

        SaleDetails memory listing = List[ticketCollection];
        require(listing.isListed, "Ticket not listed"); 
        require(listing.seller == msg.sender, "Only seller can delist");
        
        BidDetails memory currentBid = ticketBids[ticketCollection][ticketID]; 
        if (currentBid.amount > 0 && currentBid.bidder != address(0)) { 
            purchaseToken.transfer(currentBid.bidder, currentBid.amount); 
        }
        
        ITicketNFT(ticketCollection).transferFrom(address(this), listing.seller, ticketID);
        
        emit Delisting(ticketCollection, ticketID);
        delete List[ticketCollection];
    }

    function getHighestBid(address ticketCollection, uint256 ticketID) external view override returns (uint256) { 
        return ticketBids[ticketCollection][ticketID].amount; 
    }
    function getHighestBidder(address ticketCollection, uint256 ticketID) external view override returns (address) {
        return ticketBids[ticketCollection][ticketID].bidder; 
    }
    function calculateFee(uint256 amount) private pure returns (uint256) {
        return (amount * FEE_PERCENTAGE) / 100;
    }
    function getSaleDetails(address ticketCollection) external view returns (SaleDetails memory) {
        return List[ticketCollection];
    }
    function getBidDetails(address ticketCollection, uint256 ticketID) external view returns (BidDetails memory) {
        return ticketBids[ticketCollection][ticketID];
    }
}