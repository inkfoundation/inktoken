// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/VotesExtendedUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/// @title InkToken is a simple ERC20 contract with a pauseable transfer function and blacklisting
contract InkToken is ERC20VotesUpgradeable, OwnableRoles, UUPSUpgradeable {

    /// @custom:storage-location erc7201:inkfoundation.storage.InkTokenStorage
    struct InkTokenStorage {
        bool isTransferPaused;
        /// @dev The mapping of addresses to their blacklist status
        mapping(address => bool) blacklist;
        /// @dev The mapping of addresses to their whitelist status
        mapping(address => bool) whitelist;
    }

    // keccak256(abi.encode(uint256(keccak256("inkfoundation.storage.InkTokenStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant InkTokenStorageLocation = 0x3d703ba42889622c922cd461db150547d9d2bf5a2b8e10219482b2064e7e2b25;

    // Access the struct at a fixed storage slot
    function _getInkTokenStorage() internal pure returns (InkTokenStorage storage s) {
        bytes32 position = InkTokenStorageLocation;
        assembly {
            s.slot := position
        }
    }

    /// @dev The role for the DEFAULT_ADMIN_ROLE controls enabling transfers, adding/removing addresses from the blacklist and whitelist
    uint256 public constant DEFAULT_ADMIN_ROLE = _ROLE_0;

    /// @dev The error for when a transfer is attempted but transfers are paused (minting/burning is still allowed)
    error TransferPaused();
    /// @dev The error for when a transfer is attempted but the address is blacklisted
    error Blacklisted();

    /// @dev The event for when transfers are unpaused
    event TransferUnpaused();
    /// @dev The event for when a blacklist address is added
    event Blacklist(address _address, bool _isBlacklisted);
    /// @dev The event for when a blacklist address is removed
    event Whitelist(address _address, bool _isWhitelisted);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // disable this specific contract upon creation immediately as all behaviour is controlled via proxy
        _disableInitializers();
        _setOwner(address(0));
    }

    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC20Votes_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
        __EIP712_init_unchained("ink", "1"); // TODO figure out wtf this is for, it's part of ERC20VotesUpgradeable -> VotesUpgradeable
        _initializeOwner(msg.sender);
        InkTokenStorage storage s = _getInkTokenStorage();
        s.isTransferPaused = true;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Enable transfers (restricted to DEFAULT_ADMIN_ROLE and owner)
    function enableTransfer() external onlyRolesOrOwner(DEFAULT_ADMIN_ROLE) {
        InkTokenStorage storage s = _getInkTokenStorage();
        s.isTransferPaused = false;
        emit TransferUnpaused();
    }

    /// @notice Mint tokens (restricted to owner)
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Burn tokens (restricted to owner)
    function burn(address _to, uint256 _amount) public onlyOwner {
        _burn(_to, _amount);
    }

    /// @inheritdoc ERC20Upgradeable
    /// @notice Function is overridden to check if transfers are paused
    /// @notice When transfers are paused, minting/burning is still allowed
    /// @notice When transfers are paused, only whitelisted addresses can transfer
    function _update(address from, address to, uint256 value) internal override {
        InkTokenStorage storage s = _getInkTokenStorage();
        if (s.isTransferPaused && !(from == address(0) || to == address(0) || s.whitelist[from])) {
            assembly {
                mstore(0x00, 0xcd1fda9f) // `TransferPaused()`.
                revert(0x1c, 0x04)
            }
        }

        if (s.blacklist[from] || s.blacklist[to]) {
            assembly {
                mstore(0x00, 0x09550c77) // `Blacklisted()`.
                revert(0x1c, 0x04)
            }
        }
        super._update(from, to, value);
    }

    /// @inheritdoc VotesUpgradeable
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    /// @inheritdoc VotesUpgradeable
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    /// @notice Add/remove an address to the blacklist (restricted to DEFAULT_ADMIN_ROLE and owner)
    function setBlacklist(address _address, bool _isBlacklisted) external onlyRolesOrOwner(DEFAULT_ADMIN_ROLE) {
        InkTokenStorage storage s = _getInkTokenStorage();
        s.blacklist[_address] = _isBlacklisted;
        emit Blacklist(_address, _isBlacklisted);
    }

    /// @notice Add/remove an address to the whitelist (restricted to DEFAULT_ADMIN_ROLE and owner)
    function setWhitelist(address _address, bool _isWhitelisted) external onlyRolesOrOwner(DEFAULT_ADMIN_ROLE) {
        InkTokenStorage storage s = _getInkTokenStorage();
        s.whitelist[_address] = _isWhitelisted;
        emit Whitelist(_address, _isWhitelisted);
    }

    function isTransferPaused() external view returns (bool) {
        InkTokenStorage storage s = _getInkTokenStorage();
        return s.isTransferPaused;
    }

    function blacklist(address _address) external view returns (bool) {
        InkTokenStorage storage s = _getInkTokenStorage();
        return s.blacklist[_address];
    }

    function whitelist(address _address) external view returns (bool) {
        InkTokenStorage storage s = _getInkTokenStorage();
        return s.whitelist[_address];
    }
}
