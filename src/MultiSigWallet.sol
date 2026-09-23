// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MultiSigWallet is ReentrancyGuard  {
    event Deposit(address indexed sender, uint256 value);
    event SubmitTransaction(address indexed owner, uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txId);
    event RevokeConfirmation(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public immutable required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmCount;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
    
    function _onlyOwner() internal view {
        require(isOwner[msg.sender], "not owner");
    }

    modifier txExists(uint256 txId) {
        _txExists(txId);
        _;
    }
    
    function _txExists(uint256 txId) internal view {
        require(txId < transactions.length, "tx does not exist");
    }

    modifier notExecuted(uint256 txId) {
        _notExecuted(txId);
        _;
    }
    
    function _notExecuted(uint256 txId) internal view {
        require(!transactions[txId].executed, "tx already executed");
    }

    modifier notConfirmed(uint256 txId) {
        _notConfirmed(txId);
        _;
    }
    
    function _notConfirmed(uint256 txId) internal view{
        require(!confirmed[txId][msg.sender], "tx already confirmed");
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required");
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            // forge-lint: disable-next-line(require-revert-in-loop)
            require(owner != address(0), "invalid owner");

            // forge-lint: disable-next-line(require-revert-in-loop)
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitERC20Transfer(address token, address to, uint256 amount) external onlyOwner returns (uint256 txId) {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        return submitTransaction(token, 0, data);
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner returns (uint256 txId) {
        txId = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmCount: 0
        }));
        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }

    function confirmTransaction(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notConfirmed(txId)
    {
        Transaction storage txn = transactions[txId];

        // forge-lint: disable-next-line(missing-events-access-control)
        confirmed[txId][msg.sender] = true;
        txn.confirmCount += 1;
        emit ConfirmTransaction(msg.sender, txId);

        if (txn.confirmCount >= required) {
            _executeTransaction(txId);
        }
    }

    function revokeConfirmation(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        require(confirmed[txId][msg.sender], "tx not confirmed");
        Transaction storage txn = transactions[txId];

        // forge-lint: disable-next-line(missing-events-access-control)
        confirmed[txId][msg.sender] = false;
        txn.confirmCount -= 1;
        emit RevokeConfirmation(msg.sender, txId);
    }

    function _executeTransaction(uint256 txId) private nonReentrant {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "tx already executed");
        require(txn.confirmCount >= required, "cannot execute");
        txn.executed = true;

        emit ExecuteTransaction(msg.sender, txId);

        // forge-lint: disable-next-line(arbitrary-send-eth)
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);

        require(success, "tx failed");
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 txId) public view returns (address to, uint256 value, bytes memory data, bool executed, uint256 confirmCount) {
        Transaction storage txn = transactions[txId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.confirmCount);
    }
}