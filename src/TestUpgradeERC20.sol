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
    bool public is_upgraded;
    bool public v2_initialized;

    function initializeV2() public {
        require(!v2_initialized, "Already initialized");
        is_upgraded = true;
        v2_initialized = true;
    }
}
