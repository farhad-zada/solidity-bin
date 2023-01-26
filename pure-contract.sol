// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Farhad Zada - 

contract vault {

    address payable creator ;

    constructor () payable {
        creator = payable (msg.sender) ;
    }

    modifier onlyOwner () {
        require(creator == payable (msg.sender), "You're not the owner!") ;
        _ ;
    }

    receive () external payable {} 

    function depositSomeMoney () public payable returns (uint) {
        return msg.value ;
    }

    function getBalance () public view onlyOwner returns (uint) {
        return address (this) .balance ;
    }

    function takeOutWithTransfer (uint amount) public onlyOwner {
        address payable mine = payable (msg.sender) ;
        mine.transfer(amount * (10**18));
    }

    function takeOutWithSend (uint amount) public onlyOwner returns (bool) {
        address payable mine = payable (msg.sender) ;
        bool isSent = mine.send (amount * (10 ** 18)) ;
        return isSent ;
    }

    function takeOutWithCall (uint amount) public onlyOwner returns (bool, bytes memory) {
        address payable mine = payable (msg.sender) ;
        (bool isSent, bytes memory data) = mine.call {value : amount * (10**18), gas : 5000} ("") ;
        return (isSent, data) ;
    }

}
