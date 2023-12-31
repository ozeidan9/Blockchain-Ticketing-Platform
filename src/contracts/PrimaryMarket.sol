// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./PurchaseToken.sol";
import "../interfaces/IPrimaryMarket.sol";
import "./TicketNFT.sol";
import "../interfaces/IERC20.sol";

contract PrimaryMarket is IPrimaryMarket {
    IERC20 private paymentToken;
    mapping(string => address) private eventToTicketNFT;
    mapping(address => EventDetails) private ticketNFTDetails;

    struct EventDetails {
        address creator;
        uint256 price;
        uint256 maxNumberOfTickets;
        uint256 ticketsMinted;
    }

    constructor(PurchaseToken _paymentToken) {
        paymentToken = IERC20(address((_paymentToken)));
    }


    function createNewEvent(
    string memory eventName,
    uint256 price,
    uint256 maxNumberOfTickets
    ) external override returns (ITicketNFT ticketCollection) {
        require(eventToTicketNFT[eventName] == address(0), "Event already exists");

        TicketNFT newTicketNFT = new TicketNFT(eventName, maxNumberOfTickets, msg.sender, address(this));
        
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

    function getPrice(address ticketNftAddress) public view override returns (uint256) {
        return ticketNFTDetails[ticketNftAddress].price;
    }

    function purchase(
        address ticketCollection,
        string memory holderName
    ) external override returns (uint256 id) {
        EventDetails storage details = ticketNFTDetails[ticketCollection];
        require(details.ticketsMinted < details.maxNumberOfTickets, "All tickets have been minted");

        paymentToken.transferFrom(msg.sender, details.creator, details.price);
        uint256 newTicketId = ITicketNFT(ticketCollection).mint(msg.sender, holderName);
        details.ticketsMinted++;

        emit Purchase(msg.sender, ticketCollection, newTicketId, holderName);
        return newTicketId;
    }
}
