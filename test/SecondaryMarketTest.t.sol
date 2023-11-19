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

    uint256 ticketId = 0;


    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);

        vm.startPrank(address(primaryMarket));
        ticketNFT = new TicketNFT("Event", 100, charlie, address(primaryMarket));
        ticketId = ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
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

        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        assertEq(listing.seller, alice);
        assertEq(listing.price, 1 ether);
        assertTrue(listing.isListed);
    }

    function testSubmitBid() public {
        testListTicket();
        prepareBobWithTokensAndApproval(1.5 ether);
        vm.startPrank(bob);
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 1.5 ether, "Bob");
        vm.stopPrank();

        SecondaryMarket.BidDetails memory bid = secondaryMarket.getBidDetails(address(ticketNFT), ticketId);
        assertEq(bid.name, "Bob");
        assertEq(bid.bidder, bob);
        assertEq(bid.amount, 1.5 ether);
    }

    function testAcceptBid() public {
        testSubmitBid();
        vm.startPrank(alice);
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        vm.stopPrank();

        assertEq(ticketNFT.holderOf(ticketId), bob);
    }

    function testDelistTicket() public {
        testListTicket();
        vm.startPrank(alice);
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);

        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        assertFalse(listing.isListed);
        vm.stopPrank();
    }

    function testListTicketNotOwner() public {
        vm.startPrank(charlie);
        ticketId = ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert("Caller is not ticket owner");
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 1 ether);
        vm.stopPrank();

        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        console.log("listing.isListed", listing.isListed);
        assertFalse(listing.isListed);
    }

    function testSubmitBidLowAmount() public {
        testListTicket();
        prepareBobWithTokensAndApproval(0.5 ether);
        vm.startPrank(bob);
        vm.expectRevert("BidDetails must be higher than the current highest");
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 0.5 ether, "Bob");
        vm.stopPrank();

        SecondaryMarket.BidDetails memory bid = secondaryMarket.getBidDetails(address(ticketNFT), ticketId);
        assert(bid.amount != 0.5 ether);
    }

    function testAcceptBidNotSeller() public {
        testSubmitBid();
        vm.startPrank(charlie);
        vm.expectRevert("Only seller can accept bid");
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        vm.stopPrank();

        assertEq(ticketNFT.holderOf(ticketId), address(secondaryMarket));
    }

    function testDelistTicketNotSeller() public {
        testListTicket();

        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(address(secondaryMarket)),1);
        assertEq(ticketNFT.holderOf(ticketId), address (secondaryMarket)) ; 
        assertEq(ticketNFT.holderNameOf(ticketId), "Alice");

        vm.startPrank(bob);
        vm.expectRevert("Only seller can delist");

        secondaryMarket.delistTicket(address(ticketNFT), ticketId);

        vm.stopPrank();

        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        assertTrue(listing.isListed);
    }

    function testDelistTicketNotListed() public {
        vm.prank(alice);
        vm.expectRevert("Ticket not listed");
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);

        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        assertFalse(listing.isListed);
    }
}
