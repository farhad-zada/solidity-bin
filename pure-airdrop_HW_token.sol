// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract AIRDROP is ERC20 ("Ha Wo", "HW") {

    function mintToken (address[] calldata accounts, uint amount) public {

        for (uint i = 0; i < accounts.length; i++) {

        _mint(accounts[i], amount*10**18);

        }

    }

}

// [0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB]
