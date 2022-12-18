// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Farhad Zada - notes

contract NET {

    receive () external payable {}

    address[] private owners;
    mapping (address => bool) public  ownerList;
    mapping (uint => mapping(address => bool)) public  voted;

    constructor () {
        owners.push (msg.sender);
        ownerList[msg.sender] = true;

        ownerList[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        ownerList[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = true;
    }



    modifier _onlyOwner {
        require(ownerList[msg.sender] == true, "You are not an owner!");
        _;
    }

    struct Transactions {
        address sendingTo;
        uint amount;
        bool executed;
        uint approvals;
    }

    Transactions [] public proposedTransactions;

    function proposeTX (address to, uint amount) public _onlyOwner {
        proposedTransactions.push(Transactions({
            sendingTo: to,
            amount: amount,
            executed: false,
            approvals: 0
        }));
    }

    function vote (uint index) public _onlyOwner {
        require (voted[index][msg.sender] == false, "You already voted!");
        proposedTransactions[index].approvals += 1;
        voted[index][msg.sender] = true;
    }

    function execute (uint index) public _onlyOwner {
        require (proposedTransactions[index].executed == false, "This transaction already executed!");
        require (proposedTransactions[index].approvals >= proposedTransactions[index].approvals*7/10, "Not enough vote to execute!");
        address payable to = payable (proposedTransactions[index].sendingTo);
        (bool tryToSend,) = to.call{value: proposedTransactions[index].amount, gas: 5000}("");
        require (tryToSend, "You don't have enough ETH!");
        proposedTransactions[index].executed = true;
    }
}
