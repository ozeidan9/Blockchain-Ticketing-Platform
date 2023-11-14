// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "./TicketNFT.sol";
import "../interfaces/IERC20.sol";

contract PrimaryMarket is IPrimaryMarket {
    // Address of the ERC20 token used for payments
    IERC20 private paymentToken;

    // Mapping from event names to their corresponding TicketNFT addresses
    mapping(string => address) private eventToTicketNFT;

    // Struct to hold event details
    struct EventDetails {
        address creator;
        uint256 price;
        uint256 maxNumberOfTickets;
        uint256 ticketsMinted;
    }

    // Mapping from TicketNFT address to its details

    constructor(address _paymentTokenAddress) {
        paymentToken = IERC20(_paymentTokenAddress);
    }

    function createNewEvent(
        string memory eventName,
        uint256 price,
        uint256 maxNumberOfTickets
    ) external override returns (ITicketNFT ticketCollection) {
        require(eventToTicketNFT[eventName] == address(0), "Event already exists");

        // Deploy a new TicketNFT contract
        TicketNFT newTicketNFT = new TicketNFT(eventName, maxNumberOfTickets);
        
        // Save the event details
        eventToTicketNFT[eventName] = address(newTicketNFT);
        ticketNFTDetails[address(newTicketNFT)] = EventDetails({
            creator: msg.sender,
            price: price,
            maxNumberOfTickets: maxNumberOfTickets,
            ticketsMinted: 0
        });

        emit EventCreated(
            msg.sender,
            address(newTicketNFT),
            eventName,
            price,
            maxNumberOfTickets
        );

        return newTicketNFT;
    }
    // This function should return the price of a ticket for a given event (NFT contract address)
    function getPrice(address ticketNftAddress) public view returns (uint256) {
        // Implementation depends on how the price is stored in the contract
        // Example:
        // return ticketNFTDetails[address];
    }

    function purchase(
        address ticketCollection,
        string memory holderName
    ) external override returns (uint256 id) {
        EventDetails storage details = ticketNFTDetails[ticketCollection];
        
        require(details.ticketsMinted < details.maxNumberOfTickets, "All tickets have been minted");

        // Transfer ERC20 tokens from msg.sender to the event creator
        require(paymentToken.transferFrom(msg.sender, details.creator, details.price), "Payment failed");

        // Mint a new ticket
        ITicketNFT(ticketCollection).mint(msg.sender, holderName);
        details.ticketsMinted++;

        uint256 newTicketId = details.ticketsMinted;

        emit Purchase(
            msg.sender,
            ticketCollection,
            newTicketId,
            holderName
        );

        return newTicketId;
    }
}
