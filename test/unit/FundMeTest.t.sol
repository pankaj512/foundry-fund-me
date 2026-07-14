// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe, FundMe__NotOwner} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        uint256 sendValue = (5 * 10 ** 18) / 2000; // 5 USD in ETH
        fundMe.fund{value: sendValue}();
        _;
    }

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // assertEq(fundMe.getOwner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender); // because script set msg.sender to the deployer address
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // Initial price is 2000 USD so let send less then 5 USD in eth to make it fail();
        vm.expectRevert();
        uint256 sendValue = (4 * 10 ** 18) / 2000; // 4 USD in ETH
        fundMe.fund{value: sendValue}();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 sendValue = (5 * 10 ** 18) / 2000; // 5 USD in ETH
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        address funder = fundMe.getFunders(0);
        assertEq(amountFunded, sendValue);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(FundMe__NotOwner.selector);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used:", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint256 sendValue = (5 * 10 ** 18) / 2000; // 5 USD in ETH

        for (uint160 i = 1; i <= numberOfFunders; i++) {
            hoax(address(i), sendValue);
            fundMe.fund{value: sendValue}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        // fundMe.withdraw();
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
    }

    function testFallbackReceiveFunction() public funded {
        uint256 startingUserBalance = USER.balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(USER);
        (bool success, ) = address(fundMe).call{value: 1 ether}("");
        require(success, "Call failed");

        uint256 endingUserBalance = USER.balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(endingContractBalance, startingContractBalance + 1 ether);
        assertEq(startingUserBalance - endingUserBalance, 1 ether);
    }
}
