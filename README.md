<mark>**多级代理自动分账合约**</mark>

---



## 1. 合约说明

* **多签钱包**
   多签钱包是指由多个账户共同签名的钱包。多签钱包的好处是可以实现多人签名，签名数量达到一定数量后自动执行提案，从而实现多方共同管理账户，提高账户的安全性。
* **代理管理合约**
   实现代理的新增修改删除等操作，支持多级代理分账模式，每级代理设置独立分账比例。
* **分账合约**
   用户充值时资金直接转入分账合约，仅在代理主动提现时发生代币转账操作。
   用户通过代理充值时，计算直接代理所得佣金并保存在合约中，然后递归计算其上级代理所得佣金。 

---

## 2. 合约代码函数

* **MultiSigWallet**

```solidity
//发起代币转账提案
submitERC20Transfer

//发起交易提案
submitTransaction

//投票提案，达到多数通过后自动执行提案
confirmTransaction

//取消投票
revokeConfirmation

//获取钱包持有人列表
getOwners

//获取提案数量
getTransactionCount

//获取提案详情
getTransaction
```

* **AgentManager**

```solidity
//注册代理
registerAgent

//更新代理分账比例
updateAgentShare

//更新钱包地址
updateMultisig

//获取代理详情
getAgentInfo

//获取上级代理地址
getUpline

//获取分账比例
getShare
```

* **FundDistributor**

```solidity
//用户通过代理充值
deposit

//代理提现
withdrawRewards

//设置平台自动转账比例
setThreshold

//设置多签钱包地址
setMultisigWallet

//设置默认分账比例
setDefaultShare

//设置代理管理合约地址
setAgentManager

//紧急提现
emergencyWithdrawPlatform
```

---

## 3. 源码及项目运行

* **源代码**

```bash
git clone https://github.com/blockchain-jackyang/agentdistributor.git
```

* **项目运行**

```bash
cd testcontracts
forge install
```

* **运行测试用例**

```bash
forge test --match-path test/agent.t.sol
```

* **运行部署合约**

```bash
forge script script/FundDistributorDeployer.s.sol:FundDistributorDeployer --rpc-url 127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238fxxxxxxxxxxxxxxxxxxxx -vvv
```


