// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Farhad Zada - Notes

contract events {

    // events creation
    event log_1 (uint value, address account, string indexed message);
    event log_2 (uint value, address indexed account, string message);
    event log_3 (uint indexed value, address account, string message);

    function getEvent1 () public {
        emit log_1(2, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "Hello");
    }

    function getEvent2 () public {
        emit log_1(2, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "Hello");
    }

    function getEvent3 () public {
        emit log_1(2, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "Hello");
    }

}
