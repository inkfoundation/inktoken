// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {InkToken} from "../src/InkToken.sol";

contract InitialSetup is Script {
    struct Config {
        address[] blacklist;
        TokenConfig token;
        ProxyConfig proxy;
    }

    struct TokenConfig {
        string _name;
        string _symbol;
    }

    struct ProxyConfig {
        address _address;
    }

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deploy.config.json");
        string memory json = vm.readFile(path);
        bytes memory tokenData = vm.parseJson(json, ".token");
        bytes memory proxyData = vm.parseJson(json, ".proxy");
        bytes memory blacklistData = vm.parseJson(json, ".blacklist");
        TokenConfig memory tokenConfig = abi.decode(tokenData, (TokenConfig));
        ProxyConfig memory proxyConfig = abi.decode(proxyData, (ProxyConfig));
        address[] memory blacklist = abi.decode(blacklistData, (address[]));
        Config memory config = Config({
            blacklist: blacklist,
            token: tokenConfig,
            proxy: proxyConfig
        });
        address multisig_address = address(uint160(vm.envUint("MULTISIG_ADDRESS")));
        uint256 mint_amount = uint256(vm.envUint("MINT_AMOUNT"));

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Check if DEBUG environment variable is set
        bool isDebugMode = vm.envOr("DEBUG", false);

        if (isDebugMode) {
            console2.log("DEBUG MODE ENABLED");
            console2.log("deployer: ", deployer);
            console2.log("proxy address: ", config.proxy._address);
            console2.log("token name: ", config.token._name);
            console2.log("token symbol: ", config.token._symbol);
            console2.log("multisig address: ", multisig_address);
            console2.log("mint amount: ", mint_amount);
        } else {
            console2.log("deployer: ", deployer);
            console2.log("Using proxy address:", config.proxy._address);
            console2.log("Using multisig address: ", multisig_address);
            console2.log("Using mint amount: ", mint_amount);
        }

        InkToken token = InkToken(config.proxy._address);
        console2.log("decimals: ", token.decimals());
        console2.log("mint amount / decimals: ", mint_amount / (10 ** token.decimals()));


        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // blacklist each address in the blacklist
        for (uint256 i = 0; i < config.blacklist.length; i++) {
            address blacklistedAddress = config.blacklist[i];
            token.setBlacklist(blacklistedAddress, true);
            console2.log("Blacklisting address: ", blacklistedAddress);
        }

        // Do the initial mint
        token.mint(multisig_address, mint_amount);

        // Whitelist the multisig for transferring tokens
        token.setWhitelist(multisig_address, true);

        // Transfer ownership of the token to the multisig
        token.transferOwnership(multisig_address);

        vm.stopBroadcast();
    }
}
