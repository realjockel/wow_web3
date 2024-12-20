// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/bountie.sol";
import "../src/token.sol";

contract DeployBountyNFTScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy WowToken first (if not already deployed)
        WowToken wowToken = new WowToken();

        // Deploy BountyNFT with WowToken address
        BountyNFT bountyNFT = new BountyNFT(address(wowToken));

        console.log("WowToken deployed at:", address(wowToken));
        console.log("BountyNFT deployed at:", address(bountyNFT));

        vm.stopBroadcast();
    }
}

