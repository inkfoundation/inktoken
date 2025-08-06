// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InkToken} from "../src/InkToken.sol";
import "../script/Deploy.s.sol";

contract DeployScriptTest is Test {
    Deploy public deployer;
    InkToken public token;
    address public deployerAddress = vm.addr(vm.envUint("PRIVATE_KEY"));

    string internal deployedJsonContent;
    string internal expectedTokenName;
    string internal expectedTokenSymbol;

    function setUp() public {
        // Execute the main deployment script.
        deployer = new Deploy();
        deployer.run();

        // Read and parse addresses from the script's output configuration file
        string memory root = vm.projectRoot();
        string memory deployedPath = string.concat(root, "/out/deployed.config.json");
        deployedJsonContent = vm.readFile(deployedPath);
        if (bytes(deployedJsonContent).length == 0) {
            revert("Failed to read or JSON content is empty from ./out/deployed.config.json");
        }
        address tokenAddress = vm.parseJsonAddress(deployedJsonContent, ".proxy._address");

        if (tokenAddress == address(0)) {
            revert("Failed to parse token address from JSON, or address is zero.");
        }

        // Initialize contract instances with deployed addresses
        token = InkToken(tokenAddress);

        // Read and store expected values from the input deploy.config.json for assertions
        string memory deployConfigPath = string.concat(root, "/deploy.config.json");
        string memory deployConfigJsonContent = vm.readFile(deployConfigPath);
        if (bytes(deployConfigJsonContent).length == 0) {
            revert("Failed to read or JSON content is empty from ./deploy.config.json");
        }

        expectedTokenName = vm.parseJsonString(deployConfigJsonContent, ".token._name");
        expectedTokenSymbol = vm.parseJsonString(deployConfigJsonContent, ".token._symbol");
    }

    function test_Deployment_Properties() public view {
        // Assertions for token and governor properties against expected configuration values
        assertEq(token.owner(), deployerAddress, "Token owner should be the deployer of the script");

        assertEq(token.name(), expectedTokenName, "Token name should match config");
        assertEq(token.symbol(), expectedTokenSymbol, "Token symbol should match config");
    }

    function test_SerializedOutput_Properties() public view {
        // Assertions for the content of the generated deployed.config.json file
        // Token related checks in deployed.config.json
        assertEq(
            vm.parseJsonAddress(deployedJsonContent, ".proxy._address"),
            address(token),
            "Serialized token address mismatch"
        );
        assertEq(
            vm.parseJsonString(deployedJsonContent, ".proxy._name"), expectedTokenName, "Serialized token name mismatch"
        );
        assertEq(
            vm.parseJsonString(deployedJsonContent, ".proxy._symbol"),
            expectedTokenSymbol,
            "Serialized token symbol mismatch"
        );

        // Metadata related checks in deployed.config.json
        assertEq(
            vm.parseJsonAddress(deployedJsonContent, ".metadata.deployer"),
            deployerAddress,
            "Serialized deployer address mismatch"
        );
        assertTrue(
            vm.parseJsonUint(deployedJsonContent, ".metadata.startBlock") > 0, "Serialized startBlock should be > 0"
        );
    }

    function test_Run_InDebugMode() public {
        // Enable debug mode for script execution
        vm.setEnv("DEBUG", "true");

        // Re-run the deployment script in debug mode
        Deploy debugDeployer = new Deploy();
        debugDeployer.run();

        // Verify that the output configuration file is created and contains a valid token address
        string memory root = vm.projectRoot();
        string memory deployedPath = string.concat(root, "/out/deployed.config.json");
        string memory debugDeployedJsonContent = vm.readFile(deployedPath);
        assertTrue(
            bytes(debugDeployedJsonContent).length > 0, "deployed.config.json should not be empty after debug run"
        );
        address tokenAddress = vm.parseJsonAddress(debugDeployedJsonContent, ".proxy._address");
        assertTrue(tokenAddress != address(0), "Token address should be non-zero after debug run");

        // Reset debug mode environment variable
        vm.setEnv("DEBUG", "false");
    }
}
