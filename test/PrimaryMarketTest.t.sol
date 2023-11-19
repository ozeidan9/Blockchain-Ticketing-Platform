// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";

contract PrimaryMarketTest is Test {
    event EventCreated(address indexed creator, address indexed ticketCollection, string eventName, uint256 price, uint256 maxNumberOfTickets);
    event Purchase(address indexed holder, address indexed ticketCollection, uint256 ticketId, string holderName);

    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    SecondaryMarket public secondaryMarket;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);
    }

    function testCreateNewEvent() public {
        uint256 ticketPrice = 2e18;
        vm.prank(charlie);
        ITicketNFT ticketNFT;

        emit EventCreated(charlie, address(ticketNFT), "Charlie's concert", ticketPrice, 1500);
        ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, 1500);

        assertEq(ticketNFT.creator(), charlie);
        assertEq(ticketNFT.maxNumberOfTickets(), 1500);
        assertEq(primaryMarket.getPrice(address(ticketNFT)), ticketPrice);
    }

    function testPurchase() public {
        uint256 ticketPrice = 2e18;
        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, 1500);

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);

        vm.expectEmit(true, true, true, true);
        emit Purchase(alice, address(ticketNFT), 1, "Alice");
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");

        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(id), alice);
        assertEq(ticketNFT.holderNameOf(id), "Alice");
        assertEq(purchaseToken.balanceOf(alice), 100e18 - ticketPrice);
        assertEq(purchaseToken.balanceOf(charlie), ticketPrice);

        vm.stopPrank();
    }

    function testPurchaseNotEnoughBalance() public {
        uint256 ticketPrice = 2987698766544e18;

        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, 1500);

        vm.startPrank(alice); 
        vm.expectRevert("ERC20: insufficient allowance");
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");
        id++; 

        vm.stopPrank();
    }

    function testPurchaseMaxNumberOfTickets() public {
        uint256 ticketPrice = 2e18;
        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent("Charlie's concert", ticketPrice, 1);

        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);
        purchaseToken.approve(address(primaryMarket), 100e18);

        vm.expectEmit(true, true, true, true);
        emit Purchase(alice, address(ticketNFT), 1, "Alice");
        uint256 id_1 = primaryMarket.purchase(address(ticketNFT), "Alice");

        vm.expectRevert("All tickets have been minted"); 
        id_1 = primaryMarket.purchase(address(ticketNFT), "Alice");

        vm.stopPrank();
    }
}
