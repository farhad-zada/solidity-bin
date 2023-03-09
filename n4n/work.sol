// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Work {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function name() public returns (uint) {}
}
