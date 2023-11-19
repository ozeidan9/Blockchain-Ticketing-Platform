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

        vm.startPrank(address(primaryMarket));
        ticketNFT = new TicketNFT("Event", 100, charlie, address(primaryMarket));
        ticketNFT.mint(alice, "Alice");
        ticketId = 1;  // Assuming ticketId is 1 for the first mint
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

        // Accessing the SaleDetails
        // need to have seller address, ticket price, and isListed
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

        // Assertions to verify bid
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

        // Assertions to verify bid acceptance
        assertEq(ticketNFT.holderOf(ticketId), bob);
    }

    function testDelistTicket() public {

        testListTicket();
        vm.startPrank(alice);
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);

        // Assertions to verify delisting
        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        assertFalse(listing.isListed);
        vm.stopPrank();
    }

    // Failure tests with assertions
    function testFailListTicketNotOwner() public {
        vm.startPrank(bob);
        ticketNFT.mint(alice, "Alice");
        ticketId = 1;
        vm.expectRevert("Caller is not ticket owner");
        secondaryMarket.listTicket(address(ticketNFT), ticketId, 1 ether);
        vm.stopPrank();

        // Assertion to verify ticket not listed by non-owner
        SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        console.log("listing.isListed", listing.isListed);
        assertTrue(listing.isListed);
    }

    function testFailSubmitBidLowAmount() public {
        testListTicket();
        prepareBobWithTokensAndApproval(0.5 ether);
        vm.startPrank(bob);
        vm.expectRevert("Bid must be higher than the current highest");
        secondaryMarket.submitBid(address(ticketNFT), ticketId, 0.5 ether, "Bob");
        vm.stopPrank();

        // Assertion to verify bid not submitted
        SecondaryMarket.BidDetails memory bid = secondaryMarket.getBidDetails(address(ticketNFT), ticketId);
        assert(bid.amount != 0.5 ether);
    }

    function testFailAcceptBidNotSeller() public {
        testSubmitBid();
        vm.startPrank(charlie);
        vm.expectRevert("Only seller can accept bid");
        secondaryMarket.acceptBid(address(ticketNFT), ticketId);
        vm.stopPrank();

        // Assertion to verify bid not accepted by non-seller
        assertEq(ticketNFT.holderOf(ticketId), alice);
    }

    function testFailDelistTicketNotSeller() public {
        testListTicket();
        vm.startPrank(charlie);
        vm.expectRevert("Only seller can delist");
        secondaryMarket.delistTicket(address(ticketNFT), ticketId);
        vm.stopPrank();

        // Assertion to verify ticket not delisted by non-seller
        // SecondaryMarket.SaleDetails memory listing = secondaryMarket.getSaleDetails(address(ticketNFT));
        // assertTrue(listing.isListed);
    }
}
