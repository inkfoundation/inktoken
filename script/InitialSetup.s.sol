// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {InkToken} from "../src/InkToken.sol";
import {UngovernableGovernor} from "../src/UngovernableGovernor.sol";

contract InitialSetup is Script {
    struct Config {
        GovernorConfig governor;
        MetadataConfig metadata;
        TokenConfig token;
    }

    struct TokenConfig {
        address _address;
        string _name;
        string _symbol;
    }

    struct GovernorConfig {
        address _address;
        uint256 _initialProposalThreshold;
        uint256 _initialQuorumPercentage;
        uint256 _initialVoteExtension;
        uint256 _initialVotingDelay;
        uint256 _initialVotingPeriod;
        string _name;
        address _token;
    }

    struct MetadataConfig {
        address deployer;
        uint256 startBlock;
    }

    function run() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/out/deployed.config.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        Config memory config = abi.decode(data, (Config));
        address multisig_address = address(uint160(vm.envUint("MULTISIG_ADDRESS")));
        uint256 mint_amount = uint256(vm.envUint("MINT_AMOUNT"));

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // Check if DEBUG environment variable is set
        bool isDebugMode = vm.envOr("DEBUG", false);

        if (isDebugMode) {
            console2.log("DEBUG MODE ENABLED");
            console2.log("deployer: ", deployer);
            console2.log("token address: ", config.token._address);
            console2.log("token name: ", config.token._name);
            console2.log("token symbol: ", config.token._symbol);
            console2.log("multisig address: ", multisig_address);
            console2.log("mint amount: ", mint_amount);
        } else {
            console2.log("deployer: ", deployer);
            console2.log("Using token address:", config.token._address);
            console2.log("Using multisig address: ", multisig_address);
            console2.log("Using mint amount: ", mint_amount);
        }

        InkToken ungovernableERC20 = InkToken(config.token._address);
        console2.log("decimals: ", ungovernableERC20.decimals());
        console2.log("mint amount / decimals: ", mint_amount / (10 ** ungovernableERC20.decimals()));


    vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // Do the initial mint
        ungovernableERC20.mint(multisig_address, mint_amount);

        // Whitelist the multisig for transferring tokens
        ungovernableERC20.setWhitelist(multisig_address, true);

        // Transfer ownership of the token to the multisig
        ungovernableERC20.transferOwnership(multisig_address);

        vm.stopBroadcast();
    }
}
