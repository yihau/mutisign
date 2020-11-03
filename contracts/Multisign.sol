// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

struct Candidate {
    uint8 signerCount;
    mapping(address => bool) signed;
}

contract Multisign {
    event ReceiveETH(address indexed sender, uint256 indexed num);
    event NominateAddedOwner(address indexed sender, address indexed candidate);
    event AddOwner(address indexed candidate);

    mapping(address => Candidate) addCandidates;

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

    function getAddCandidateSignerCount(address addr) external view returns(uint8) {
      return addCandidates[addr].signerCount;
    }

    function addOwner(address addr) external {
        require(owners[msg.sender], "only owners can do this");
        require(!owners[addr], "already is one of owner");
        require(
            !addCandidates[addr].signed[msg.sender],
            "already nominate this candidate"
        );
        emit NominateAddedOwner(msg.sender, addr);
        addCandidates[addr].signerCount++;
        if (addCandidates[addr].signerCount >= requireMinimum) {
            delete addCandidates[addr];
            owners[addr] = true;
            emit AddOwner(addr);
        } else {
            addCandidates[addr].signed[msg.sender] = true;
        }
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}
