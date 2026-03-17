// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";
import "../src/AgentManager.sol";
import "../src/FundDistributor.sol";

contract FundDistributorDeployer is Script {
    function  setUp()  public{
        
    }

    function run() public returns(address,address,address){

        address usdtAddr = vm.envAddress("AGENT_USDT_ADDR");
        if(usdtAddr == address(0)) revert();

        //read property admins from environment variables
        string memory adminsJson = vm.envString("AGENT_MULTISIGWALLET_OWNERS");
        string[] memory propertyAdminArray = vm.parseJsonStringArray(adminsJson,"");
        address[] memory propertyOwners = new address[](propertyAdminArray.length);
        for(uint i = 0; i < propertyAdminArray.length; i++){
            address adminAddress = vm.parseAddress(propertyAdminArray[i]);
            if(adminAddress == address(0)) revert();
            propertyOwners[i] = adminAddress;
        }

        vm.startBroadcast();
        
        //deploy wallet contract
        MultiSigWallet wallet = new MultiSigWallet(propertyOwners, 2);
        if(address(wallet) == address(0)) revert();

        //deploy agent manager contract
        AgentManager agentManager = new AgentManager(address(wallet));
        if(address(agentManager) == address(0)) revert();
        
        //deploy fund distributor contract
        FundDistributor fundDistributor = new FundDistributor(usdtAddr,address(wallet), address(agentManager),1000,10000);
        if(address(fundDistributor) == address(0)) revert();

        vm.stopBroadcast();

        return (address(wallet),address(agentManager),address(fundDistributor));
    }
}