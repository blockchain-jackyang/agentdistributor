// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/IAgentManager.sol";
import "../src/AgentManager.sol";
import "../src/MultiSigWallet.sol";
import "../src/FundDistributor.sol";
import "../src/BasicToken.sol";

contract FundDistributorTest is Test 
{    
    BasicToken usdt;
    AgentManager agentManager;
    FundDistributor fundDistributor;
    MultiSigWallet multiSigWallet;

    address amdmin1=makeAddr("admin1");
    address amdmin2=makeAddr("admin2");
    address amdmin3=makeAddr("admin3");
    address amdmin4=makeAddr("admin4");
    address amdmin5=makeAddr("admin5");
    address amdmin6=makeAddr("admin6");
    address amdmin7=makeAddr("admin7");

    address to=makeAddr("to");


    address agent1=makeAddr("agent1");
    address agent2=makeAddr("agent2");
    address agent3=makeAddr("agent3");

    address user1=makeAddr("user1");
    address user2=makeAddr("user2");
    address user3=makeAddr("user3");

    function setUp() public {
        usdt= new BasicToken("USDT", "USDT");
        address[] memory owners= new address[](7);
        owners[0]=amdmin1;
        owners[1]=amdmin2;
        owners[2]=amdmin3;
        owners[3]=amdmin4;
        owners[4]=amdmin5;
        owners[5]=amdmin6;
        owners[6]=amdmin7;
        multiSigWallet=new MultiSigWallet(owners,4);
        agentManager=new AgentManager(address(multiSigWallet));
        fundDistributor=new FundDistributor(address(usdt),address(multiSigWallet),address(agentManager),1000,500);


        //为钱包合约账户铸造代币
        //usdt.mint(address(multiSigWallet),1000000);
        // usdt.mint(user1,15000);
        // usdt.mint(user2,25000);
        // usdt.mint(user3,35000);

        // vm.deal(user1,10 eth);
    }


    //wallet test
    function test_MultiSigWallet_01_submitERC20Transfer() public 
    {
        vm.startPrank(amdmin1);
        uint256 txId = multiSigWallet.submitERC20Transfer(address(usdt),to,2000);
        vm.stopPrank();

        (address dest,uint256 val,,bool _excuted,uint256 _confirmed) = multiSigWallet.getTransaction(txId);

        assertEq(dest,address(usdt));
        assertEq(val,0);
        assertEq(_excuted,false);
        assertEq(_confirmed,0);
    }

    function test_MultiSigWallet_02_submitTransaction() public 
    {
        vm.startPrank(amdmin1);
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, 2000);
        uint256 txId = multiSigWallet.submitTransaction(address(usdt),0,data);
        vm.stopPrank();

        (address dest,uint256 val,,bool _excuted,uint256 _confirmed) = multiSigWallet.getTransaction(txId);

        assertEq(dest,address(usdt));
        assertEq(val,0);
        assertEq(_excuted,false);
        assertEq(_confirmed,0);
    }

    function test_MultiSigWallet_03_confirmTransaction() public 
    {
        vm.startPrank(amdmin1);
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, 2000);
        uint256 txId = multiSigWallet.submitTransaction(address(usdt),0,data);
        vm.stopPrank();

        vm.startPrank(amdmin2);
        multiSigWallet.confirmTransaction(txId);
        vm.stopPrank();

        vm.startPrank(amdmin3);
        multiSigWallet.confirmTransaction(txId);
        vm.stopPrank();

        (,,,,uint256 _confirmed) = multiSigWallet.getTransaction(txId); 

        assertEq(_confirmed,2);
    }

    function test_MultiSigWallet_04_revokeConfirmation() public 
    {
        vm.startPrank(amdmin1);
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, 2000);
        uint256 txId = multiSigWallet.submitTransaction(address(usdt),0,data);
        vm.stopPrank();

        vm.startPrank(amdmin2);
        multiSigWallet.confirmTransaction(txId);
        vm.stopPrank();

        vm.startPrank(amdmin3);
        multiSigWallet.confirmTransaction(txId);
        vm.stopPrank();

        (,,,,uint256 _confirmed) = multiSigWallet.getTransaction(txId); 

        assertEq(_confirmed,2);


        //revokeConfirmation
        vm.startPrank(amdmin2);
        multiSigWallet.revokeConfirmation(txId);
        vm.stopPrank();

        (,,,,uint256 _confirmed2) = multiSigWallet.getTransaction(txId); 
        assertEq(_confirmed2,1);
    }

    function test_MultiSigWallet_05_getOwners() public view
    {
        address[] memory owners= multiSigWallet.getOwners();
        assertEq(owners.length,7);
        assertEq(owners[6],amdmin7);
    }

    function test_MultiSigWallet_06_getTransactionCount() public
    {
        uint256 count = multiSigWallet.getTransactionCount();
        assertEq(count,0);

        //create proposal
        vm.startPrank(amdmin1);
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, 2000);
        multiSigWallet.submitTransaction(address(usdt),0,data);
        vm.stopPrank();

        count = multiSigWallet.getTransactionCount();
        assertEq(count,1);
    }

    function test_MultiSigWallet_07_getTransaction() public
    {
        vm.startPrank(amdmin1);
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, 2000);
        uint256 txId = multiSigWallet.submitTransaction(address(usdt),0,data);
        vm.stopPrank();

        (address dest,uint256 val,,bool _excuted,uint256 _confirmed) = multiSigWallet.getTransaction(txId);

        assertEq(dest,address(usdt));
        assertEq(val,0);
        assertEq(_excuted,false);
        assertEq(_confirmed,0);
    }

    // agent test
    function test_AgentManager_01_registerAgent() public 
    {
        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,500);
        vm.stopPrank();

        (address upline, uint256 share, bool exists) = agentManager.getAgentInfo(agent2);
        assertEq(exists,true);
        assertEq(upline,agent1);
        assertEq(share,500);

        (upline, share, exists) = agentManager.getAgentInfo(agent1);
        assertEq(exists,true);
        assertEq(upline,address(0));
        assertEq(share,500);
    }

    function test_AgentManager_02_updateAgentShare() public
    {
        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,500);
        agentManager.updateAgentShare(agent2,1000);
        vm.stopPrank();

        (address upline, uint256 share, bool exists) = agentManager.getAgentInfo(agent2);
        assertEq(exists,true);
        assertEq(upline,agent1);
        assertEq(share,1000);
    }

    function test_AgentManager_03_getUpline() public
    {
        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,500);
        agentManager.updateAgentShare(agent2,1000);
        vm.stopPrank();

        address upline = agentManager.getUpline(agent2);
        assertEq(upline,agent1);
    }

    function test_AgentManager_04_getUpline() public
    {
        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,500);
        agentManager.updateAgentShare(agent2,1000);
        vm.stopPrank();

        uint256 share = agentManager.getShare(agent2);
        assertEq(share,1000);
    }

    function test_AgentManager_05_getAgentInfo() public
    {
        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,500);
        agentManager.updateAgentShare(agent2,1000);
        vm.stopPrank();

        (address upline, uint256 share, bool exists) = agentManager.getAgentInfo(agent2);
        assertEq(exists,true);
        assertEq(upline,agent1);
        assertEq(share,1000);
    }

    function test_FundDistributor_01_deposit()  public {

        usdt.mint(user1,15000);

        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,5000);
        vm.stopPrank();

        console.log("fundDistributor balance:",usdt.balanceOf(address(fundDistributor)));

        vm.startPrank(user1);
        usdt.approve(address(fundDistributor),15000);
        fundDistributor.deposit(5000,agent2);
        vm.stopPrank();

        console.log("user1 balance:",usdt.balanceOf(address(user1)));
        assertEq(usdt.balanceOf(user1),10000);

        console.log("agent1 balance:",usdt.balanceOf(address(agent1)));
        console.log("agent2 balance:",usdt.balanceOf(address(agent2)));        

        console.log("fundDistributor balance:",usdt.balanceOf(address(fundDistributor)));

        console.log("platformBalance:",fundDistributor.platformBalance());
    }

    function test_FundDistributor_02_withdrawRewards()  public {

        usdt.mint(user1,15000);

        vm.startPrank(address(multiSigWallet));
        agentManager.registerAgent(agent1,address(0),500);
        agentManager.registerAgent(agent2,agent1,5000);
        vm.stopPrank();

        // console.log("fundDistributor balance:",usdt.balanceOf(address(fundDistributor)));

        vm.startPrank(user1);
        usdt.approve(address(fundDistributor),15000);
        fundDistributor.deposit(5000,agent2);
        vm.stopPrank();

        console.log("user1 balance:",usdt.balanceOf(address(user1)));
        assertEq(usdt.balanceOf(user1),10000);

        console.log("agent2 balance:",usdt.balanceOf(address(agent2)));    

        vm.startPrank(agent2);
        fundDistributor.withdrawRewards();
        vm.stopPrank();

        console.log("agent2 balance:",usdt.balanceOf(address(agent2))); 
        assertEq(usdt.balanceOf(address(agent2)),2500);      


        vm.startPrank(agent1);
        fundDistributor.withdrawRewards();
        vm.stopPrank();

        console.log("agent1 balance:",usdt.balanceOf(address(agent1))); 
        assertEq(usdt.balanceOf(address(agent1)),125);  
    }
}

