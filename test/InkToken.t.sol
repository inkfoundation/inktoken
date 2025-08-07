// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {InkToken} from "../src/InkToken.sol";
import {TestUpgradeERC20} from "./TestUpgradeERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract InkTokenTest is Test {
    InkToken token;

    address contractOwner;
    address bob;
    address charlie;

    function setUp() public {
        contractOwner = address(1);
        vm.label(contractOwner, "contractOwner");
        bob = address(2);
        vm.label(bob, "bob");
        charlie = address(3);
        vm.label(charlie, "charlie");

        vm.startPrank(contractOwner);
        token = InkToken(Upgrades.deployUUPSProxy(
            "InkToken.sol",
            abi.encodeCall(InkToken.initialize, ("InkToken", "INK"))
        ));
        vm.stopPrank();
    }

    function test_constructor() public {
        assertEq(token.owner(), address(1), "Owner should be set to address(1)");
        assertEq(token.balanceOf(address(1)), 0, "Balance of owner should be 0");
        assertEq(token.totalSupply(), 0, "Total supply should be 0");
        assertEq(token.decimals(), 18, "Decimals should be 18");
        assertEq(token.isTransferPaused(), true, "Transfer should be paused");
        assertEq(token.name(), "InkToken", "Name should be InkToken");
        assertEq(token.symbol(), "INK", "Symbol should be INK");
    }

    function test_enableTransferAndBurnOwnership_success() public {
        vm.prank(contractOwner);
        token.enableTransfer();
        assertEq(token.isTransferPaused(), false, "Transfer should be enabled");
    }

    function test_enableTransferAndBurnOwnership_revert_Unauthorized() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, bob));
        token.enableTransfer();
    }

    function test_transfer_revert_TransferPaused() public {
        vm.prank(contractOwner);
        token.mint(bob, 100);
        vm.prank(bob);
        vm.expectRevert(InkToken.TransferPaused.selector);
        token.transfer(charlie, 100);
    }

    function test_transfer_success() public {
        vm.prank(contractOwner);
        token.mint(bob, 100);
        vm.prank(contractOwner);
        token.enableTransfer();
        vm.prank(bob);
        token.transfer(charlie, 100);
        assertEq(token.balanceOf(charlie), 100, "Balance of charlie should be 100");
    }

    function test_mint_revert_Unauthorized() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, bob));
        token.mint(charlie, 100);
    }

    function test_mint_success() public {
        // transfer is paused
        vm.prank(contractOwner);
        token.mint(bob, 100);
        assertEq(token.balanceOf(bob), 100, "Balance of bob should be 100");
    }

    function test_burn_revert_Unauthorized() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, bob));
        token.burn(charlie, 100);
    }

    function test_burn_success() public {
        // transfer is paused
        vm.prank(contractOwner);
        token.mint(bob, 100);
        assertEq(token.balanceOf(bob), 100, "Balance of bob should be 100");
        vm.prank(contractOwner);
        token.burn(bob, 100);
        assertEq(token.balanceOf(bob), 0, "Balance of bob should be 0");
    }

    function test_CLOCK_MODE_success() public {
        assertEq(token.CLOCK_MODE(), "mode=timestamp", "CLOCKMODE is not correct");
    }

    function test_clock_success() public {
        assertEq(token.clock(), block.timestamp, "clock is not correct");
    }

    function test_setBlacklist_success() public {
        vm.expectEmit();
        emit InkToken.Blacklist(bob, true);
        vm.prank(contractOwner);
        token.setBlacklist(bob, true);
        assertEq(token.blacklist(bob), true, "bob should be blacklisted");
    }

    function test_setWhitelist_success() public {
        vm.expectEmit();
        emit InkToken.Whitelist(bob, true);
        vm.prank(contractOwner);
        token.setWhitelist(bob, true);
        assertEq(token.whitelist(bob), true, "bob should be whitelisted");
    }

    function test_setBlacklist_revert_Unauthorized() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, bob));
        token.setBlacklist(charlie, true);
    }

    function test_setWhitelist_revert_Unauthorized() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, bob));
        token.setWhitelist(charlie, true);
    }

    function test_transfer_revert_Blacklisted() public {
        vm.expectEmit();
        emit InkToken.Blacklist(bob, true);
        vm.prank(contractOwner);
        token.setBlacklist(bob, true);
        vm.prank(contractOwner);
        token.enableTransfer();
        vm.prank(bob);
        vm.expectRevert(InkToken.Blacklisted.selector);
        token.transfer(charlie, 100);
    }

    function test_transfer_success_Whitelisted() public {
        vm.expectEmit();
        emit InkToken.Whitelist(bob, true);
        vm.prank(contractOwner);
        token.setWhitelist(bob, true);
        vm.prank(contractOwner);
        token.mint(bob, 100);
        vm.prank(bob);
        token.transfer(charlie, 100);
        assertEq(token.balanceOf(charlie), 100, "Balance of charlie should be 100");
    }

    function test_storageLocation() public {
        bytes32 expected = 0x86f2ca1115f2bb314b972c713d24abb994cd161b5975fbaec2c44af89270f000;
        bytes32 actual = keccak256(abi.encode(uint256(keccak256("inkfoundation.storage.InkToken")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(actual, expected, "Storage location mismatch");
    }

    function test_initializeOnlyOnce() public {
        // Attempt to initialize again should revert
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        token.initialize("InkToken", "INK");
    }

    // TODO test can't call upgrade on token directly

    function test_upgrade() public {
        // set some state variables before the upgraded
        vm.startPrank(contractOwner);
        token.setWhitelist(contractOwner, true);
        token.setBlacklist(charlie, true);
        token.mint(contractOwner, 1000);
        token.transfer(bob, 100);
        vm.stopPrank();

        // assert current state
        assertEq(token.whitelist(contractOwner), true);
        assertEq(token.blacklist(charlie), true);
        assertEq(token.balanceOf(contractOwner), 900);
        assertEq(token.balanceOf(bob), 100);

        // Upgrade the contract
        vm.startPrank(contractOwner);
        Upgrades.upgradeProxy(
            address(token),
            "TestUpgradeERC20.sol",
            abi.encodeCall(TestUpgradeERC20.initializeV2, ())
        );
        vm.stopPrank();
        TestUpgradeERC20 upgradedToken = TestUpgradeERC20(address(token));

        // Verify that the upgrade was successful
        assertEq(upgradedToken.isUpgraded(), true, "Token should be upgraded");
        assertEq(upgradedToken.owner(), contractOwner, "Owner should remain unchanged after upgrade");

        // Assert state hasn't changed
        assertEq(token.whitelist(contractOwner), true);
        assertEq(token.blacklist(charlie), true);
        assertEq(token.balanceOf(contractOwner), 900);
        assertEq(token.balanceOf(bob), 100);

        // Verify can only call initializeV2 once
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vm.prank(contractOwner);
        upgradedToken.initializeV2();
    }
}
