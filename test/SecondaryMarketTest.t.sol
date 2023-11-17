// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.10;

// import "forge-std/Test.sol";
// import "../src/contracts/PurchaseToken.sol";
// import "../src/contracts/TicketNFT.sol";
// import "../src/contracts/SecondaryMarket.sol";
// import "../src/interfaces/ISecondaryMarket.sol";

// contract SecondaryMarketTest is Test{
//     SecondaryMarket secondaryMarket;
//     PurchaseToken purchaseToken;
//     TicketNFT ticketNFT;

//     address alice = makeAddr("alice");
//     address bob = makeAddr("bob");
//     address charlie = makeAddr("charlie");

//     uint256 ticketId;

//     function setUp() public {
//         purchaseToken = new PurchaseToken();
//         ticketNFT = new TicketNFT("Event", 100, charlie, address(this));
//         secondaryMarket = new SecondaryMarket(purchaseToken);

//         // Mint a ticket for Alice
//         ticketNFT.mint(alice, "Alice");
//         ticketId = 1; // Assuming ticketId is 1 for the first mint

//         // Setting up balances and approvals
//         purchaseToken.mint{value: 10 ether}(alice);
//         purchaseToken.mint{value: 10 ether}(bob);
//         purchaseToken.approve(address(secondaryMarket), type(uint256).max, alice);
//         purchaseToken.approve(address(secondaryMarket), type(uint256).max, bob);
//     }

//     // Test listing a ticket
//     function testListTicket() public {
//         vm.startPrank(alice);
//         ticketNFT.approve(address(secondaryMarket), ticketId);
//         vm.expectEmit(true, true, true, true);
//         emit SecondaryMarket.Listing(alice, address(ticketNFT), ticketId, 1 ether);
//         secondaryMarket.listTicket(address(ticketNFT), ticketId, 1 ether);
//         vm.stopPrank();
//     }

//     // Test submitting a bid
//     function testSubmitBid() public {
//         testListTicket(); // First list the ticket

//         vm.startPrank(bob);
//         vm.expectEmit(true, true, true, true);
//         emit ISecondaryMarket.Submitted(bob, address(ticketNFT), ticketId, 1.5 ether, "Bob");
//         secondaryMarket.submitBid(address(ticketNFT), ticketId, 1.5 ether, "Bob");
//         vm.stopPrank();
//     }

//     // Test accepting a bid
//     function testAcceptBid() public {
//         testSubmitBid(); // First submit a bid

//         vm.startPrank(alice);
//         vm.expectEmit(true, true, true, true);
//         emit ISecondaryMarket.BidAccepted(bob, address(ticketNFT), ticketId, 1.5 ether, "Bob");
//         secondaryMarket.acceptBid(address(ticketNFT), ticketId);
//         vm.stopPrank();
//     }

//     // Test delisting a ticket
//     function testDelistTicket() public {
//         testListTicket(); // First list the ticket

//         vm.startPrank(alice);
//         vm.expectEmit(true, true, false, false);
//         emit ISecondaryMarket.Delisting(address(ticketNFT), ticketId);
//         secondaryMarket.delistTicket(address(ticketNFT), ticketId);
//         vm.stopPrank();
//     }

//     // Additional tests can be added for edge cases and failure scenarios
// }
