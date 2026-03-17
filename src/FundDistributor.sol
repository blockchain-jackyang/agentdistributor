// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IAgentManager.sol";

contract FundDistributor is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdt;
    address public multisigWallet;
    uint256 public threshold;           // 自动划扣阈值（USDT 数量，需考虑小数位数）
    uint256 public platformBalance;      // 平台当前累计资金
    uint256 public defaultShare;         // 默认分成比例（当代理未注册时使用，单位：基点）
    IAgentManager public agentManager;

    // 待提取的奖励
    mapping(address => uint256) public pendingRewards;

    event Deposited(address indexed user, uint256 amount, address indexed agent);
    event RewardsDistributed(address indexed agent, uint256 reward);
    event PlatformWithdrawn(address indexed to, uint256 amount);
    event AutoTransfer(uint256 amount, address indexed multisig);
    event ThresholdUpdated(uint256 newThreshold);
    event MultisigUpdated(address indexed newMultisig);
    event DefaultShareUpdated(uint256 newDefaultShare);
    event AgentManagerUpdated(address indexed newManager);

    modifier onlyMultisig() {
        _onlyMultisig();
        _;
    }
    
    function _onlyMultisig() internal view {
        require(msg.sender == multisigWallet, "only multisig");
    }

    constructor(
        address _usdt,
        address _multisigWallet,
        address _agentManager,
        uint256 _threshold,
        uint256 _defaultShare
    ) {
        require(_usdt != address(0), "invalid USDT");
        require(_multisigWallet != address(0), "invalid multisig");
        require(_agentManager != address(0), "invalid agentManager");
        usdt = IERC20(_usdt);
        multisigWallet = _multisigWallet;
        agentManager = IAgentManager(_agentManager);
        threshold = _threshold;
        defaultShare = _defaultShare;
    }

    // 用户充值并指定起始代理
    function deposit(uint256 _amount, address _agent) external nonReentrant {
        require(_amount > 0, "amount zero");
        require(_agent != address(0), "agent zero");

        // 将用户 USDT 转入本合约
        usdt.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 remaining = _amount;
        address current = _agent;
        uint256 maxDepth = 10; // 防止 gas 耗尽

        while (current != address(0) && remaining > 0 && maxDepth-- > 0) {
            
            (address upline, uint256 share, bool exists) = agentManager.getAgentInfo(current);
            
            if (!exists) break;

            if (share == 0) {
                share = defaultShare; // 未注册代理使用默认比例
            }
            if (share > 0) {
                // 从剩余金额中计算该代理应得（基于当前剩余）
                uint256 reward = remaining * share / 10000;
                if (reward > 0) {
                    pendingRewards[current] += reward; // 记账
                    remaining -= reward;
                    emit RewardsDistributed(current, reward);
                }
            }
            current = upline; // 移动到上级
        }

        // 剩余部分累加到平台资金池
        platformBalance += remaining;

        emit Deposited(msg.sender, _amount, _agent);

        // 检查自动划扣条件
        if (platformBalance >= threshold) {
            _autoTransfer();
        }
    }

    // 代理提取待领取的奖励
    function withdrawRewards() external nonReentrant {
        uint256 amount = pendingRewards[msg.sender];
        require(amount > 0, "no rewards");
        pendingRewards[msg.sender] = 0;
        usdt.safeTransfer(msg.sender, amount);
    }

    // 内部自动划扣：将全部平台资金转给多签钱包
    function _autoTransfer() private {
        uint256 amount = platformBalance;
        platformBalance = 0;
        usdt.safeTransfer(multisigWallet, amount);
        emit AutoTransfer(amount, multisigWallet);
    }

    // 以下管理函数仅限多签钱包调用
    function setThreshold(uint256 _newThreshold) external onlyMultisig {
        threshold = _newThreshold;
        emit ThresholdUpdated(_newThreshold);
    }

    function setMultisigWallet(address _newMultisig) external onlyMultisig {
        require(_newMultisig != address(0), "invalid address");
        multisigWallet = _newMultisig;
        emit MultisigUpdated(_newMultisig);
    }

    function setDefaultShare(uint256 _newDefaultShare) external onlyMultisig {
        require(_newDefaultShare <= 10000, "share too high");
        defaultShare = _newDefaultShare;
        emit DefaultShareUpdated(_newDefaultShare);
    }

    function setAgentManager(address _newManager) external onlyMultisig {
        require(_newManager != address(0), "invalid address");
        
        try IAgentManager(_newManager).getAgentInfo(address(0)) returns (address, uint256, bool) {

            agentManager = IAgentManager(_newManager);
            emit AgentManagerUpdated(_newManager);
        } catch {
            revert("AgentManager: invalid interface");
        }
    }

    // 紧急情况下手动提取平台资金（例如多签钱包地址错误时）
    function emergencyWithdrawPlatform(address _to, uint256 _amount) external onlyMultisig {
        require(_amount <= platformBalance, "insufficient balance");
        platformBalance -= _amount;
        usdt.safeTransfer(_to, _amount);
        emit PlatformWithdrawn(_to, _amount);
    }
}