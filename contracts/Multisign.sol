// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Multisign {
    event ReceiveETH(address indexed sender, uint256 indexed num);

    constructor() public {}

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}
