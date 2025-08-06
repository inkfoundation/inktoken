// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/VotesExtendedUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/// @title InkToken is a simple ERC20 contract with a pauseable transfer function and blacklisting
contract InkToken is ERC20VotesUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    /// @custom:storage-location erc7201:inkfoundation.storage.InkToken
    struct InkTokenStorage {
        bool isTransferPaused;
        /// @dev The mapping of addresses to their blacklist status
        mapping(address => bool) blacklist;
        /// @dev The mapping of addresses to their whitelist status
        mapping(address => bool) whitelist;
    }

    /// @dev keccak256(abi.encode(uint256(keccak256("inkfoundation.storage.InkToken")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INK_TOKEN_STORAGE_LOCATION = 0x86f2ca1115f2bb314b972c713d24abb994cd161b5975fbaec2c44af89270f000;

    function _getInkTokenStorage() internal pure returns (InkTokenStorage storage $) {
        assembly {
            $.slot := INK_TOKEN_STORAGE_LOCATION
        }
    }

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
        _disableInitializers();
    }

    /// @custom:oz-upgrades-validate-as-initializer
    function initialize(string memory _name, string memory _symbol) public reinitializer(1) {
        __ERC20_init_unchained(_name, _symbol);
        __ERC20Votes_init_unchained();
        __EIP712_init_unchained("InkToken", "1");
        __Ownable_init(msg.sender);
        InkTokenStorage storage $ = _getInkTokenStorage();
        $.isTransferPaused = true;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Enable transfers (restricted to owner)
    function enableTransfer() external onlyOwner {
        InkTokenStorage storage $ = _getInkTokenStorage();
        $.isTransferPaused = false;
        emit TransferUnpaused();
    }

    /// @notice Mint tokens (restricted to owner)
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Burn tokens (restricted to owner)
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    /// @inheritdoc ERC20Upgradeable
    /// @notice Function is overridden to check if transfers are paused
    /// @notice When transfers are paused, minting/burning is still allowed
    /// @notice When transfers are paused, only whitelisted addresses can transfer
    function _update(address from, address to, uint256 value) internal override {
        InkTokenStorage storage $ = _getInkTokenStorage();
        if ($.isTransferPaused && !(from == address(0) || to == address(0) || $.whitelist[from])) {
            assembly {
                mstore(0x00, 0xcd1fda9f) // `TransferPaused()`.
                revert(0x1c, 0x04)
            }
        }

        if ($.blacklist[from] || $.blacklist[to]) {
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

    /// @notice Add/remove an address to the blacklist (restricted to owner)
    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        InkTokenStorage storage $ = _getInkTokenStorage();
        $.blacklist[_address] = _isBlacklisted;
        emit Blacklist(_address, _isBlacklisted);
    }

    /// @notice Add/remove an address to the whitelist (restricted to owner)
    function setWhitelist(address _address, bool _isWhitelisted) external onlyOwner {
        InkTokenStorage storage $ = _getInkTokenStorage();
        $.whitelist[_address] = _isWhitelisted;
        emit Whitelist(_address, _isWhitelisted);
    }

    function isTransferPaused() external view returns (bool) {
        InkTokenStorage storage $ = _getInkTokenStorage();
        return $.isTransferPaused;
    }

    function blacklist(address _address) external view returns (bool) {
        InkTokenStorage storage $ = _getInkTokenStorage();
        return $.blacklist[_address];
    }

    function whitelist(address _address) external view returns (bool) {
        InkTokenStorage storage $ = _getInkTokenStorage();
        return $.whitelist[_address];
    }
}
