// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {InkToken} from "../src/InkToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract Deploy is Script {
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

        // Check if DEBUG environment variable is set
        bool isDebugMode = vm.envOr("DEBUG", false);
        if (isDebugMode) {
            console2.log("DEBUG MODE ENABLED");
            console2.log("name: ", config.token._name);
            console2.log("symbol: ", config.token._symbol);
        }

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        console2.log("deployer: ", deployer);

        // deploy token contract + proxy
        address proxy = Upgrades.deployUUPSProxy(
            "InkToken.sol",
            abi.encodeCall(InkToken.initialize, (config.token._name, config.token._symbol))
        );
        vm.stopBroadcast();

        string memory deployments = "deployments";
        string memory proxyJson = "proxy";

        vm.serializeString(proxyJson, "_name", config.token._name);
        vm.serializeString(proxyJson, "_symbol", config.token._symbol);

        vm.serializeString(
            deployments,
            "proxy",
            vm.serializeAddress(proxyJson, "_address", address(proxy))
        );

        string memory metadataJson = "metadata";
        vm.serializeAddress(metadataJson, "deployer", deployer);
        vm.writeJson(
            vm.serializeString(deployments, "metadata", vm.serializeUint(metadataJson, "startBlock", block.number)),
            "./out/deployed.config.json"
        );
    }
}
