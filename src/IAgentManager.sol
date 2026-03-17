// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgentManager {
    function getShare(address _agent) external view returns (uint256);
    function getUpline(address _agent) external view returns (address);
    function getAgentInfo(address _agent) external view returns (address upline, uint256 share, bool exists);
}