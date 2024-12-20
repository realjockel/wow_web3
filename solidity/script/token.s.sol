// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/token.sol";

contract DeployWowTokenScript is Script {
    function run() external returns (WowToken) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        WowToken token = new WowToken();
        console.log("Token deployed at:", address(token));

        vm.stopBroadcast();
        return token;
    }
}
