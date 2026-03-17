// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAgentManager.sol";

contract AgentManager is IAgentManager {
    address public multisigWallet;

    struct AgentInfo {
        address upline;      // 上级代理地址，0表示无上级
        uint256 share;       // 分成比例，单位：基点（1/10000），例如 500 = 5%
        bool exists;
    }

    mapping(address => AgentInfo) public agents;

    event AgentRegistered(address indexed agent, address indexed upline, uint256 share);
    event AgentShareUpdated(address indexed agent, uint256 newShare);
    event MultisigUpdated(address indexed newMultisig);

    modifier onlyMultisig() {
        _onlyMultisig();
        _;
    }
    
    function _onlyMultisig() internal view {
        require(msg.sender == multisigWallet, "only multisig");
    }

    constructor(address _multisigWallet) {
        require(_multisigWallet != address(0), "invalid multisig");
        multisigWallet = _multisigWallet;
    }

    // 注册新代理，必须由多签调用
    function registerAgent(address _agent, address _upline, uint256 _share) external onlyMultisig {
        require(_agent != address(0), "invalid agent");
        require(!agents[_agent].exists, "already registered");
        require(_share <= 10000, "share too high"); // 最多100%
        if (_upline != address(0)) {
            require(agents[_upline].exists, "upline not registered");
        }

        agents[_agent] = AgentInfo({
            upline: _upline,
            share: _share,
            exists: true
        });

        emit AgentRegistered(_agent, _upline, _share);
    }

    // 更新代理分成比例，仅多签
    function updateAgentShare(address _agent, uint256 _newShare) external onlyMultisig {
        require(agents[_agent].exists, "agent not exists");
        require(_newShare <= 10000, "share too high");
        agents[_agent].share = _newShare;
        emit AgentShareUpdated(_agent, _newShare);
    }

    // 更新多签钱包地址，仅当前多签自己调用（可通过多签交易执行）
    function updateMultisig(address _newMultisig) external onlyMultisig {
        require(_newMultisig != address(0), "invalid multisig");
        multisigWallet = _newMultisig;
        emit MultisigUpdated(_newMultisig);
    }

    // 查询代理信息
    function getAgentInfo(address _agent) external view returns (address upline, uint256 share, bool exists) {
        AgentInfo memory info = agents[_agent];
        return (info.upline, info.share, info.exists);
    }

    // 获取代理的上级
    function getUpline(address _agent) external view returns (address) {
        return agents[_agent].upline;
    }

    // 获取代理的分成比例
    function getShare(address _agent) external view returns (uint256) {
        if (agents[_agent].exists) {
            return agents[_agent].share;
        }
        return 0; // 未注册代理视为0分成
    }
}