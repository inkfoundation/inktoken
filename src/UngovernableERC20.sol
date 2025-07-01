// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {Votes} from "@openzeppelin/contracts/governance/utils/VotesExtended.sol";
import {ERC20, ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {OwnableRoles} from "solady/src/auth/OwnableRoles.sol";

/// @title UngovernableERC20 is a simple ERC20 contract with a pauseable transfer function and blacklisting
contract UngovernableERC20 is ERC20Votes, OwnableRoles {
    bool public isTransferPaused = true;
    /// @dev The error for when a transfer is attempted but transfers are paused (minting/burning is still allowed)

    error TransferPaused();
    /// @dev The error for when a transfer is attempted but the address is blacklisted
    error Blacklisted();

    /// @dev The role for the DEFAULT_ADMIN_ROLE controls enabling transfers, adding/removing addresses from the blacklist and whitelist
    uint256 public constant DEFAULT_ADMIN_ROLE = _ROLE_0;
    /// @dev The mapping of addresses to their blacklist status
    mapping(address => bool) public blacklist;
    /// @dev The mapping of addresses to their whitelist status
    mapping(address => bool) public whitelist;

    /// @dev The event for when transfers are unpaused
    event TransferUnpaused();
    /// @dev The event for when a blacklist address is added
    event Blacklist(address _address, bool _isBlacklisted);
    /// @dev The event for when a blacklist address is removed
    event Whitelist(address _address, bool _isWhitelisted);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) EIP712(_name, "1") {
        _initializeOwner(msg.sender);
    }

    /// @notice Enable transfers (restricted to DEFAULT_ADMIN_ROLE and owner)
    function enableTransfer() external onlyRolesOrOwner(DEFAULT_ADMIN_ROLE) {
        isTransferPaused = false;
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

    /// @inheritdoc ERC20
    /// @notice Function is overridden to check if transfers are paused
    /// @notice When transfers are paused, minting/burning is still allowed
    /// @notice When transfers are paused, only whitelisted addresses can transfer
    function _update(address from, address to, uint256 value) internal override {
        if (isTransferPaused && !(from == address(0) || to == address(0) || whitelist[from])) {
            assembly {
                mstore(0x00, 0xcd1fda9f) // `TransferPaused()`.
                revert(0x1c, 0x04)
            }
        }

        if (blacklist[from] || blacklist[to]) {
            assembly {
                mstore(0x00, 0x09550c77) // `Blacklisted()`.
                revert(0x1c, 0x04)
            }
        }
        super._update(from, to, value);
    }

    /// @inheritdoc Votes
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    /// @inheritdoc Votes
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    /// @notice Add/remove an address to the blacklist (restricted to DEFAULT_ADMIN_ROLE and owner)
    function setBlacklist(address _address, bool _isBlacklisted) external onlyRolesOrOwner(DEFAULT_ADMIN_ROLE) {
        blacklist[_address] = _isBlacklisted;
        emit Blacklist(_address, _isBlacklisted);
    }

    /// @notice Add/remove an address to the whitelist (restricted to DEFAULT_ADMIN_ROLE and owner)
    function setWhitelist(address _address, bool _isWhitelisted) external onlyRolesOrOwner(DEFAULT_ADMIN_ROLE) {
        whitelist[_address] = _isWhitelisted;
        emit Whitelist(_address, _isWhitelisted);
    }
}
