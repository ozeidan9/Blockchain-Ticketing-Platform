// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {

    uint256 private _currentTicketId = 0;
    address private _creator;
    string private _eventName;
    uint256 private _maxNumberofTickets;

    
    mapping(uint256 => address) private _ticketOwners;
    mapping(address => uint256) private _ownerTicketCount;
    mapping(uint256 => string) private _ticketHolderNames;
    mapping(uint256 => uint256) private _ticketExpiryDates;
    mapping(uint256 => bool) private _ticketUsedFlags;
    mapping(uint256 => address) private _ticketApprovals;
    mapping(uint256 => string) private _ticketEventNames;

    modifier onlyCreator() {
        require(msg.sender == _creator, "Caller is not the creator");
        _;
    }

    modifier onlyTicketOwner(uint256 ticketID) {
        require(msg.sender == _ticketOwners[ticketID], "Caller is not the ticket owner");
        _;
    }

    modifier ticketExists(uint256 ticketID) {
        require(_ticketOwners[ticketID] != address(0), "Ticket does not exist");
        _;
    }

    // constructor() {
    //     _creator = msg.sender;
    // }

    constructor(string memory eventName,uint256 maxNumberofTickets) { 
        // TODO
        _creator = msg.sender;
        _eventName = eventName;
        _maxNumberofTickets = maxNumberofTickets;

    }

    function maxNumberOfTickets() external view override returns (uint256) {
        return _maxNumberofTickets;
    }

    function creator() external view override returns (address) {
        return _creator;
    }

    function mint(address holder, string memory holderName) external onlyCreator {
        _currentTicketId++;
        uint256 newTicketId = _currentTicketId;

        _ticketOwners[newTicketId] = holder;
        _ownerTicketCount[holder]++;
        _ticketHolderNames[newTicketId] = holderName;
        _ticketExpiryDates[newTicketId] = block.timestamp + 10 days;
        _ticketUsedFlags[newTicketId] = false;

        emit Transfer(address(0), holder, newTicketId);
    }

    function balanceOf(address holder) external view override returns (uint256 balance) {
        return _ownerTicketCount[holder];
    }

    function holderOf(uint256 ticketID) external view override ticketExists(ticketID) returns (address holder) {
        return _ticketOwners[ticketID];
    }

    function transferFrom(address from,address to, uint256 ticketID) external override ticketExists(ticketID) {
        require(from != address(0) && to != address(0), "Invalid from or to address");
        require(msg.sender == _ticketOwners[ticketID] || msg.sender == _ticketApprovals[ticketID], "Caller is not owner nor approved");

        _ownerTicketCount[from]--;
        _ownerTicketCount[to]++;
        _ticketOwners[ticketID] = to;
        _ticketApprovals[ticketID] = address(0);

        emit Transfer(from, to, ticketID);
        emit Approval(_ticketOwners[ticketID], address(0), ticketID);
    }

    function approve(address to, uint256 ticketID) external override onlyTicketOwner(ticketID) ticketExists(ticketID) {
        _ticketApprovals[ticketID] = to;
        emit Approval(msg.sender, to, ticketID);
    }

    function getApproved(uint256 ticketID) external view override ticketExists(ticketID) returns (address operator) {
        return _ticketApprovals[ticketID];
    }

    function holderNameOf(uint256 ticketID) external view override ticketExists(ticketID) returns (string memory holderName) {
        return _ticketHolderNames[ticketID];
    }

    function updateHolderName(uint256 ticketID, string calldata newName) external override onlyTicketOwner(ticketID) ticketExists(ticketID) {
        _ticketHolderNames[ticketID] = newName;
    }

    function setUsed(uint256 ticketID) external override onlyCreator ticketExists(ticketID) {
        require(!_ticketUsedFlags[ticketID], "Ticket is already used");
        require(block.timestamp <= _ticketExpiryDates[ticketID], "Ticket has expired");

        _ticketUsedFlags[ticketID] = true;
    }

    function isExpiredOrUsed(uint256 ticketID) external view override ticketExists(ticketID) returns (bool) {
        return _ticketUsedFlags[ticketID] || block.timestamp > _ticketExpiryDates[ticketID];
    }

    function eventNameOf(uint256 ticketID) external view ticketExists(ticketID) returns (string memory) {
        return _ticketEventNames[ticketID];
    }
}