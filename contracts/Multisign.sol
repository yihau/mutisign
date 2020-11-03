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
    event NominateRemoveOwner(
        address indexed sender,
        address indexed candidate
    );
    event RemoveOwner(address indexed candidate);

    mapping(address => Candidate) addCandidates;
    mapping(address => Candidate) removeCandidates;

    uint8 public requireMinimum;
    uint256 public ownersCount;
    mapping(address => bool) public owners;

    constructor(address[] memory initOwners, uint8 initMinimumRequired) public {
        require(
            initOwners.length >= initMinimumRequired,
            "owners count should greater than or equal to require minimum"
        );
        for (uint256 i = 0; i < initOwners.length; i++) {
            owners[initOwners[i]] = true;
        }
        ownersCount = initOwners.length;
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
            ownersCount++;
            emit AddOwner(addr);
        } else {
            addCandidates[addr].signed[msg.sender] = true;
        }
    }

    function getRemoveCandidateSignerCount(address addr)
        external
        view
        returns (uint8)
    {
        return removeCandidates[addr].signerCount;
    }

    function removeOwner(address addr) external {
        require(owners[msg.sender], "only owners can do this");
        require(owners[addr], "address is not one of owner");
        require(
            !removeCandidates[addr].signed[msg.sender],
            "already nominate this candidate"
        );
        require(ownersCount > requireMinimum, "owner not enough");
        emit NominateRemoveOwner(msg.sender, addr);
        removeCandidates[addr].signerCount++;
        if (removeCandidates[addr].signerCount >= requireMinimum) {
            delete removeCandidates[addr];
            delete owners[addr];
            ownersCount--;
            emit RemoveOwner(addr);
        } else {
            removeCandidates[addr].signed[msg.sender] = true;
        }
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}
