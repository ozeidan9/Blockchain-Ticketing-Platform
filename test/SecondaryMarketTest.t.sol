// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";
import "../src/interfaces/ISecondaryMarket.sol";

contract SecondaryMarketTest is Test {
    SecondaryMarket secondaryMarket;
    PurchaseToken purchaseToken;
    PrimaryMarket primaryMarket;
    TicketNFT ticketNFT;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    uint256 ticketId;

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);

        ticketNFT = new TicketNFT("Event", 100, charlie, address(this));
        ticketNFT.mint(alice, "Alice");
        ticketId = 1;  // Assuming ticketId is 1 for the first mint
    }

    function prepareAliceWithTokensAndApproval(uint256 amount) internal {
        vm.startPrank(alice);
        purchaseToken.mint{value: amount}();
        purchaseToken.approve(address(secondaryMarket), amount);
        vm.stopPrank();
    }

    function prepareBobWithTokensAndApproval(uint256 amount) internal {
        vm.startPrank(bob);
        purchaseToken.mint{value: amount}();
        purchaseToken.approve(address(secondaryMarket), amount);
        vm.stopPrank();
    }

    function testListTicket() public {
        prepareAliceWithTokensAndApproval(1 ether);
        vm.startPrank(alice);
        ticketNFT.approve(address(secondaryMarket), ticketId);
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 1 ether);
        vm.stopPrank();
    }

    function testSubmitBid() public {
        testListTicket();
        prepareBobWithTokensAndApproval(1.5 ether);
        vm.startPrank(bob);
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 1.5 ether, "Bob");
        vm.stopPrank();
    }

    function testAcceptBid() public {
        testSubmitBid();
        vm.startPrank(alice);
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        vm.stopPrank();
    }

    function testDelistTicket() public {
        testListTicket();
        vm.startPrank(alice);
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);
        vm.stopPrank();
    }

    function testFailListTicketNotOwner() public {
        vm.startPrank(bob); // Bob, who is not the owner, tries to list the ticket
        ticketNFT.mint(alice, "Alice");
        ticketId = 1; // Assuming the first minted ticketId is 1
        vm.expectRevert("Caller is not ticket owner");
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 1 ether);
        vm.stopPrank();
    }


    function testFailSubmitBidLowAmount() public {
        testListTicket();
        prepareBobWithTokensAndApproval(0.5 ether);
        vm.startPrank(bob);
        vm.expectRevert("Bid must be higher than the current highest");
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 0.5 ether, "Bob");
        vm.stopPrank();
    }

    function testFailAcceptBidNotSeller() public {
        // Ensure Alice lists the ticket and Bob makes a bid
        testListTicket();
        testSubmitBid();

        vm.startPrank(charlie); // Charlie, not the seller, tries to accept the bid
        vm.expectRevert("Only seller can accept bid");
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        vm.stopPrank();
    }

    function testFailDelistTicketNotSeller() public {
        testListTicket(); // Alice lists the ticket
        vm.prank(charlie);
        vm.startPrank(charlie); // Charlie, not the seller, tries to delist
        vm.expectRevert("Only seller can delist");
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);
        vm.stopPrank();
    }
}
