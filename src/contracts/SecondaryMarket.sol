// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./TicketNFT.sol";
import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IERC20.sol";

contract SecondaryMarket is ISecondaryMarket {
    // Define the fee as 5%
    uint256 public constant FEE_PERCENTAGE = 5;

    // ERC20 token used for transactions
    IERC20 public purchaseToken;

    // Define a struct to hold the listing information
    struct TicketListingInfo {
        address holder;
        uint256 price;
        address highestBidder;
        uint256 highestBid;
        string highestBidderName; 
    }

    // Mapping from ticket collection and ticketID to their respective listing
    mapping(address => mapping(uint256 => TicketListingInfo)) public listings;

    // Reference to the ITicketNFT interface
    ITicketNFT private ticketNFT;

    constructor(address _purchaseToken) {
        purchaseToken = IERC20(_purchaseToken);
    }

    function getHighestBid(
    address ticketCollection,
    uint256 ticketId
    ) external view override returns (uint256) {
        return listings[ticketCollection][ticketId].highestBid;
    }

    function getHighestBidder(
        address ticketCollection,
        uint256 ticketId
    ) external view override returns (address) {
        return listings[ticketCollection][ticketId].highestBidder;
    }


   function listTicket(
    address ticketCollection,
    uint256 ticketID,
    uint256 price
    ) external override {
        // Make sure the ticket exists and is not expired or used
        require(
            !ITicketNFT(ticketCollection).isExpiredOrUsed(ticketID),
            "Ticket is expired or already used"
        );

        // Transfer the ticket to this contract
        ITicketNFT(ticketCollection).transferFrom(msg.sender, address(this), ticketID);

        // Create the listing in the internal mapping
        listings[ticketCollection][ticketID] = TicketListingInfo({
            holder: msg.sender,
            price: price,
            highestBidder: address(0),
            highestBid: 0,
            highestBidderName: ""

        });

        // Emit the Listing event as defined in the ISecondaryMarket interface
        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }


    function submitBid(
        address ticketCollection,
        uint256 ticketID,
        uint256 bidAmount,
        string calldata name
    ) external override {
        TicketListingInfo storage listing = listings[ticketCollection][ticketID];
        require(
            bidAmount > listing.highestBid,
            "Bid must be higher than the current highest"
        );
        
        // Refund the previous highest bidder if there is one
        if (listing.highestBidder != address(0)) {
            purchaseToken.transfer(listing.highestBidder, listing.highestBid);
        }

        // Transfer bid amount from bidder to contract
        purchaseToken.transferFrom(msg.sender, address(this), bidAmount);

        // Update the listing with the new highest bid and bidder's name
        listing.highestBidder = msg.sender;
        listing.highestBid = bidAmount;
        listing.highestBidderName = name;

        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }

    function acceptBid(address ticketCollection, uint256 ticketID) external override {
        TicketListingInfo storage listing = listings[ticketCollection][ticketID];
        require(listing.highestBidder != address(0), "No bid to accept");

        // Calculate the fee and the amount to transfer to the ticket holder
        uint256 fee = (listing.highestBid * FEE_PERCENTAGE) / 100;
        uint256 amountToHolder = listing.highestBid - fee;

        // Transfer the ERC20 tokens to the ticket holder minus the fee
        purchaseToken.transfer(listing.holder, amountToHolder);

        // Transfer the fee to the creator of the ticket collection
        address creator = ITicketNFT(ticketCollection).creator();
        purchaseToken.transfer(creator, fee);

        // Transfer the ticket to the highest bidder
        ITicketNFT(ticketCollection).updateHolderName(ticketID, listing.highestBidderName);
        ITicketNFT(ticketCollection).transferFrom(address(this), listing.highestBidder, ticketID);

        // Emit BidAccepted event
        emit BidAccepted(listing.highestBidder, ticketCollection, ticketID, listing.highestBid, listing.highestBidderName);

        // Remove the listing
        delete listings[ticketCollection][ticketID];
    }

    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        TicketListingInfo storage listing = listings[ticketCollection][ticketID];
        require(msg.sender == listing.holder, "Only the lister can delist the ticket");

        // Refund the highest bidder if there is one
        if (listing.highestBidder != address(0)) {
            purchaseToken.transfer(listing.highestBidder, listing.highestBid);
        }

        // Transfer the ticket back to the lister
        ITicketNFT(ticketCollection).transferFrom(address(this), msg.sender, ticketID);

        // Remove the listing
        delete listings[ticketCollection][ticketID];

        emit Delisting(ticketCollection, ticketID);
    }
}
