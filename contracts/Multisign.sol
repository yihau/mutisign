// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Multisign {
    event ReceiveETH(address indexed sender, uint256 indexed num);

    uint8 public requireMinimum;
    mapping(address => bool) public owners;

    constructor(address[] memory initOwners, uint8 initMinimumRequired) public {
        require(
            initOwners.length >= initMinimumRequired,
            "owners count should greater than or equal to require minimum"
        );
        for (uint256 i = 0; i < initOwners.length; i++) {
            owners[initOwners[i]] = true;
        }
        requireMinimum = initMinimumRequired;
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}
