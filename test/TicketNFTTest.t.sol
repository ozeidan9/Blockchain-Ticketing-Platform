// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/interfaces/IERC20.sol";

 
contract TicketNFTTest is Test {
    TicketNFT public ticketNFT;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public primaryMarket = makeAddr("primaryMarket");

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    function setUp() public {
        ticketNFT = new TicketNFT("Charlie's concert", 100, charlie, primaryMarket);
    }

    function testMint() public {
        vm.startPrank(charlie); 
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(1), alice);
    }

    function testTransfer() public {
        vm.startPrank(charlie);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, bob, 1);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(bob), 1);
    }

    function testApprovedTransfer() public {
        vm.startPrank(charlie);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.holderOf(1), alice);
        vm.stopPrank();
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        assertEq(ticketNFT.getApproved(1), bob);
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, charlie, 1);
        ticketNFT.transferFrom(alice, charlie, 1);
        assertEq(ticketNFT.balanceOf(alice), 0);
        assertEq(ticketNFT.balanceOf(charlie), 1);
    }

    function testUpdateHolderName() public {
        vm.startPrank(charlie);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.holderNameOf(1), "Alice");
        vm.stopPrank();
        vm.prank(alice);
        ticketNFT.updateHolderName(1, "Bob");
        assertEq(ticketNFT.holderNameOf(1), "Bob");
    }

    function testUpdateHolderAfterSelfTransferingTicketWithApproval() public {
        vm.startPrank(charlie);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Approval(alice, bob, 1);
        ticketNFT.approve(bob, 1);
        vm.prank(bob);
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, bob, 1);
        ticketNFT.transferFrom(alice, bob, 1);
        assertEq(ticketNFT.holderOf(1), bob);
        vm.prank(bob);
        ticketNFT.updateHolderName(1, "Bob");
        assertEq(ticketNFT.holderNameOf(1), "Bob");
    }

    function testSetTicketToUsed() public{
        vm.startPrank(charlie);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.isExpiredOrUsed(1), false);
        ticketNFT.setUsed(1);
        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        vm.stopPrank();
    } 

    function testMintAsPrimaryMarket() public {
        vm.startPrank(primaryMarket); 
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), alice, 1);
        uint256 ticketID = ticketNFT.mint(alice, "Alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(ticketID), alice);
        vm.stopPrank();
    }



    function testMintAsNonOwner() public {
        vm.prank(bob);
        vm.expectRevert("Caller is not the creator");
        ticketNFT.mint(alice, "Alice");
    }

    function testHolderOfInvalidTicket() public {
        vm.expectRevert("Ticket does not exist");
        ticketNFT.holderOf(1);
    }


    function testTransferWithInvalidAdresses() public {
        vm.startPrank(charlie);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert("Invalid from or to address");
        ticketNFT.transferFrom(address(0), bob, 1);

        vm.prank(alice);
        vm.expectRevert("Invalid from or to address");
        ticketNFT.transferFrom(alice, address(0), 1);
    }

    function testTransferWithoutApproval() public {
        vm.startPrank(charlie);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("Caller is not owner nor approved");
        ticketNFT.transferFrom(alice, bob, 1);
    }


    function testApproveAsNonHolder() public {
        vm.expectEmit(true, true, true, true);
        vm.startPrank(charlie);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        vm.prank(bob);
        vm.expectRevert("Caller is not the ticket owner");
        ticketNFT.approve(bob, 1);
    }

    function testUpdateHolderNameAsNonHolder() public {
        vm.expectEmit(true, true, true, true);
        vm.startPrank(charlie);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        vm.prank(bob);
        vm.expectRevert("Caller is not the ticket owner");
        ticketNFT.updateHolderName(1, "Bob");
    }

    function testSetTicketAsUsedAsNonPrimaryMarket() public {
        vm.expectEmit(true, true, true, true);
        vm.startPrank(charlie);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.stopPrank();
        vm.expectRevert("Caller is not the creator");
        ticketNFT.setUsed(1);
    }

    function testSetTicketAsUsedForUsedTicket() public {
        vm.expectEmit(true, true, true, true);
        vm.startPrank(charlie);
        emit Transfer(address(0), alice, 1);

        ticketNFT.mint(alice, "Alice");

        ticketNFT.setUsed(1);
        vm.expectRevert("Ticket is already used");
        ticketNFT.setUsed(1);
        vm.stopPrank();
    }

    function testSetTicketAsUsedForExpiredTicket() public {
        vm.expectEmit(true, true, true, true);
        vm.startPrank(charlie);
        emit Transfer(address(0), alice, 1);
        ticketNFT.mint(alice, "Alice");
        vm.warp(1977361197);

        assertEq(ticketNFT.isExpiredOrUsed(1), true);
        vm.expectRevert("Ticket has expired");

        ticketNFT.setUsed(1);
        vm.stopPrank();
    }

}