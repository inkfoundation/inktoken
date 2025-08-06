// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import "./InkToken.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/VotesExtendedUpgradeable.sol";

/// @title TestUpgradeERC20 is a simple ERC20 contract with a pauseable transfer function and blacklisting
/// @custom:oz-upgrades-from InkToken
contract TestUpgradeERC20 is InkToken {
    /// @custom:storage-location erc7201:inkfoundation.storage.TestUpgrade
    struct TestupgradeStorage {
        bool is_upgraded;
    }

    /// @dev keccak256(abi.encode(uint256(keccak256("inkfoundation.storage.TestUpgrade")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TESTUPGRADE_STORAGE_LOCATION = 0x9023b368a60893ace0b4efea70b313397c5d06b6c718506907bdddf8f8f28b00;

    function _getTestupgradeStorage() private pure returns (TestupgradeStorage storage $) {
        assembly {
            $.slot := TESTUPGRADE_STORAGE_LOCATION
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV2() public reinitializer(2) {
        TestupgradeStorage storage $ = _getTestupgradeStorage();
        $.is_upgraded = true;
    }

    function isUpgraded() public view returns (bool) {
        TestupgradeStorage storage $ = _getTestupgradeStorage();
        return $.is_upgraded;
    }
}
