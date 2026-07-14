// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        console.log("Funding contract with address:", mostRecentlyDeployed);
        FundMe fundMe = FundMe(payable(mostRecentlyDeployed));
        vm.startBroadcast();
        fundMe.fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded contract with value:", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        console.log(
            "Withdrawing from contract with address:",
            mostRecentlyDeployed
        );
        FundMe fundMe = FundMe(payable(mostRecentlyDeployed));
        vm.startBroadcast();
        fundMe.cheaperWithdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}
