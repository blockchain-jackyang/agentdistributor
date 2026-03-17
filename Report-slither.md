Summary
 - [unused-return](#unused-return) (1 results) (Medium)
 - [calls-loop](#calls-loop) (1 results) (Low)
## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-0
[FundDistributor.setAgentManager(address)](src/agent/FundDistributor.sol#L130-L140) ignores return value by [() = IAgentManager(_newManager).getAgentInfo(address(0))](src/agent/FundDistributor.sol#L135-L140)

src/agent/FundDistributor.sol#L130-L140


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-1
[FundDistributor.deposit(uint256,address)](src/agent/FundDistributor.sol#L54-L95) has external calls inside a loop: [(upline,share,exists) = agentManager.getAgentInfo(current)](src/agent/FundDistributor.sol#L69-L71)

src/agent/FundDistributor.sol#L54-L95


