// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract chaman {

    receive () external payable {}

    uint private voteNeeded = 3;
    mapping (address => bool) public owners;
    mapping (uint => mapping (address => bool)) public voted;
    
    constructor () payable {
        // I predefined these addreses for sake of symplicity
        owners[msg.sender] = true;
        owners[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        owners[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = true;
        owners[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = true;
        owners[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = true;
    }

    struct proposal {
        address payable sendTo;
        uint amount;
        bool executed;
        uint approvals;
    }

    proposal[] public proposals;

    modifier onlyOwners () {
        require(owners[msg.sender] == true, "Not owner!");
        _;
    }

    function proposeTX (address to, uint amount) public {
        proposals.push(proposal({
            sendTo: payable (to),
            amount: amount,
            executed: false,
            approvals: 0
        }));
    }

    // function executeTX(uint to) public onlyOwners{
    //     require(proposals[to].approvals >= voteNeeded, "NOT ENOUGH APPROVALS");
    //     require(proposals[to].executed == false, "Already transacted");
    //     address payable toSend = payable(proposals[to].sendTo);

    //     // if(proposals[to].sendTo == address(0)){
    //     //     approvalsNeeded = proposedTransactions[index].value;
    //     // }else{
    //     (bool tryToSend, ) = toSend.call{value: proposals[to].amount, gas: 5000}("");
    //     require(tryToSend, "You don't have enough ETH to send");
    // // }
    // }

    function vote (uint to) public onlyOwners {
        require (voted[to][msg.sender] == false, "You have voted!");
        require (proposals[to].executed == false, "This transaction has already been executed!");
        proposals[to].approvals += 1;
        voted[to][msg.sender] = true;
        if (proposals[to].approvals >= voteNeeded) {
            (bool isSent, ) = proposals[to].sendTo.call{value: proposals[to].amount, gas: 5000} ("");
            require (isSent, "You don't have enough ETH!");
            proposals[to].executed = true;
        }
        
    }


    function revoke (uint to) public onlyOwners {
        require (proposals[to].executed == false, "This transaction has already been executed!");
        require (voted[to][msg.sender] == true, "You have not voted!");
        proposals[to].approvals -= 1;
        voted[to][msg.sender] = false;
    }

}

// 0xdD870fA1b7C4700F2BD7f44238821C26f7392148
