// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IAgentManager {
    struct AgentInfo {
        address upline;      // 上级代理地址，0表示无上级
        uint256 share;       // 分成比例，单位：基点（1/10000），例如 500 = 5%
        bool exists;
    }

    function getShare(address _agent) external view returns (uint256);
    function getUpline(address _agent) external view returns (address);
    function getAgentInfo(address _agent) external view returns (address upline, uint256 share, bool exists);
    function getAgentChain(address start, uint256 maxDepth) external view returns (AgentInfo[] memory chain);
}