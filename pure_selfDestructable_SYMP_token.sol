// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Farhad Zada - Note: This code involves only the logic behind the selfdestruction process.

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract token is ERC20 ("Sympathy", "SYMP") {
    
    address private owner; 
    constructor () payable  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner, "You are not the owner!");
        _;
    }

    mapping (address => uint) private points;

    function mintNewToken (uint amount) public onlyOwner {
        _mint(msg.sender, amount*(10**18));
    }

    function mapBurned (uint amount) public {
        _burn (msg.sender, amount*(10**18));
        points[msg.sender] += amount*(10**18);
    }

    function burned (address who) public view returns (uint) {
        return points[who];
    }

    function win () public {
        if (points[msg.sender] >= 5*(10**18)) { 
            selfdestruct(payable (msg.sender));
        }
        else {
            revert ("You don't have enough points!");
        }
    }

}
