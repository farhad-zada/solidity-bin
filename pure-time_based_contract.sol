// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract TENET {

    uint private totalPerDay = 60; 
    mapping (address => uint) private lastTimeSpent;
    mapping (address => uint) private lastAmountSpent;
    mapping (address => uint) private balance;

    function getBalance (address who) public view returns (uint) {

        return balance[who];

    }

    function transferApply (address to, uint amount) public {

        require (balance[msg.sender] >= amount, "You don't have enough balance!");

        if (exclusions[msg.sender] == true) {

            lastTimeSpent[msg.sender] = block.timestamp;
            lastAmountSpent[msg.sender] = amount;

            // transfer :
            balance[msg.sender] -= amount;
            balance[to] += amount;

        }

        else {

            require (amount < totalPerDay, "It's more than total daily trade amount!");

            if (lastTimeSpent[msg.sender] - block.timestamp > 1 minutes / 6) {

                lastTimeSpent[msg.sender] = block.timestamp;
                lastAmountSpent[msg.sender] = amount;

                // transfer :
                balance[msg.sender] -= amount;
                balance[to] += amount;

            }

            else {

                if (lastAmountSpent[msg.sender] + amount <= totalPerDay) {

                    lastTimeSpent[msg.sender] = block.timestamp;
                    lastAmountSpent[msg.sender] += amount;

                    // transfer :
                    balance[msg.sender] -= amount;
                    balance[to] += amount;
                }

                else {

                    revert ("You can't spent more than 5 ZWs per day!");

                }

            }

        }

    }

    function mintFive () public {

        balance[msg.sender] += 5;

    }

    mapping (address => bool) private exclusions;

    function exclude (address who) public {

        exclusions[who] = !exclusions[who];

    }
    
}

