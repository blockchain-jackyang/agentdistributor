// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MultiSigWallet is ReentrancyGuard  {
    event Deposit(address indexed sender, uint value);
    event SubmitTransaction(address indexed owner, uint indexed txId, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event RevokeConfirmation(address indexed owner, uint indexed txId);
    event ExecuteTransaction(address indexed owner, uint indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public immutable required;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint confirmCount;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public confirmed;

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
    
    function _onlyOwner() internal view {
        require(isOwner[msg.sender], "not owner");
    }

    modifier txExists(uint txId) {
        _txExists(txId);
        _;
    }
    
    function _txExists(uint txId) internal view {
        require(txId < transactions.length, "tx does not exist");
    }

    modifier notExecuted(uint txId) {
        _notExecuted(txId);
        _;
    }
    
    function _notExecuted(uint txId) internal view {
        require(!transactions[txId].executed, "tx already executed");
    }

    modifier notConfirmed(uint txId) {
        _notConfirmed(txId);
        _;
    }
    
    function _notConfirmed(uint txId) internal view{
        require(!confirmed[txId][msg.sender], "tx already confirmed");
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitERC20Transfer(address token, address to, uint256 amount) external onlyOwner returns (uint txId) {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        return submitTransaction(token, 0, data);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner returns (uint txId) {
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

    function confirmTransaction(uint txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notConfirmed(txId)
    {
        Transaction storage txn = transactions[txId];
        confirmed[txId][msg.sender] = true;
        txn.confirmCount += 1;
        emit ConfirmTransaction(msg.sender, txId);

        if (txn.confirmCount >= required) {
            _executeTransaction(txId);
        }
    }

    function revokeConfirmation(uint txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        require(confirmed[txId][msg.sender], "tx not confirmed");
        Transaction storage txn = transactions[txId];
        confirmed[txId][msg.sender] = false;
        txn.confirmCount -= 1;
        emit RevokeConfirmation(msg.sender, txId);
    }

    function _executeTransaction(uint txId) private nonReentrant {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "tx already executed");
        require(txn.confirmCount >= required, "cannot execute");
        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "tx failed");
        emit ExecuteTransaction(msg.sender, txId);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint txId) public view returns (address to, uint value, bytes memory data, bool executed, uint confirmCount) {
        Transaction storage txn = transactions[txId];
        return (txn.to, txn.value, txn.data, txn.executed, txn.confirmCount);
    }
}