// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/dao.sol";
import "../src/token.sol";

contract DeployGuildDAOScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // First, deploy the WowToken
        WowToken token = new WowToken();
        
        // Now deploy the GuildDAO
        GuildDAO dao = new GuildDAO(
            "MyGuildDAO",
            IERC20(address(token)),
            1 days,  // voting delay
            1 weeks, // voting period
            100 * 10**18, // proposal threshold (100 tokens)
            4 // quorum percentage (4%)
        );

        console.log("GuildDAO deployed at:", address(dao));
        console.log("WowToken deployed at:", address(token));

        vm.stopBroadcast();
    }
}
