//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract InteractionsTest is Test {

    uint256 public constant FUND_AMOUNT = 3 ether;

    Raffle raffle;
    HelperConfig public helperConfig;
    VRFCoordinatorV2_5Mock vrfCoordinatorMock;
    address vrfCoordinator;
    uint256 subscriptionId;
    address linkToken;
    address account;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        subscriptionId = config.subscriptionId;
        linkToken = config.linkToken;
        account = config.account;

        vrfCoordinatorMock = VRFCoordinatorV2_5Mock(vrfCoordinator);
    }

    function testUserCanCreateSubscription() public {
        // Arrange
        CreateSubscription createSubscriptionContract = new CreateSubscription();
        (subscriptionId, vrfCoordinator) = createSubscriptionContract.createSubscription(vrfCoordinator, account); 
        
        // Act / Assert
        assert(subscriptionId > 0);
    }

    function testUserCanFundSubscription() public {
        // Arrange
        CreateSubscription createSubscriptionContract = new CreateSubscription();
        (subscriptionId, vrfCoordinator) = createSubscriptionContract.createSubscription(vrfCoordinator, account); 

        (uint96 balanceBeforeFunding, , , , ) = vrfCoordinatorMock.getSubscription(subscriptionId);
        console.log("balance before funding: ", balanceBeforeFunding);
        
        FundSubscription fundSubscriptionContract = new FundSubscription();
        fundSubscriptionContract.fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);

        (uint96 balanceAfterFunding, , , , ) = vrfCoordinatorMock.getSubscription(subscriptionId);
        console.log("balance after funding: ", balanceAfterFunding);

        // Act / Assert
        assert(balanceAfterFunding == (balanceBeforeFunding + (FUND_AMOUNT * 100)));
    }

    function testUserCanAddConsumer() public {
        // Arrange
        CreateSubscription createSubscriptionContract = new CreateSubscription();
        (subscriptionId, vrfCoordinator) = createSubscriptionContract.createSubscription(vrfCoordinator, account); 

        FundSubscription fundSubscriptionContract = new FundSubscription();
        fundSubscriptionContract.fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);

        AddConsumer addConsumerContract = new AddConsumer();
        addConsumerContract.addConsumer(address(raffle), vrfCoordinator, subscriptionId, account);
        
        // Act / Assert
        (, , , , address[] memory consumers) = vrfCoordinatorMock.getSubscription(subscriptionId);
        assert(consumers.length > 0);
    }
} 