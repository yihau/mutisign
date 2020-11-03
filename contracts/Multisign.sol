// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

struct Candidate {
    uint8 signerCount;
    mapping(address => bool) signed;
}

struct Tx {
    uint8 signerCount;
    mapping(address => bool) signed;
    address payable to;
    uint256 value;
    bool send;
}

contract Multisign {
    event ReceiveETH(address indexed sender, uint256 indexed num);
    event NominateAddedOwner(address indexed sender, address indexed candidate);
    event AddOwner(address indexed candidate);
    event NominateRemoveOwner(address indexed sender, address indexed candidate);
    event RemoveOwner(address indexed candidate);
    event BuildETHTx(address indexed sender, uint256 TxID);
    event ApproveETHTx(address indexed sender, uint256 TxID);
    event SendETHTx(address indexed sender, uint256 TxID);

    uint256 txNum;
    mapping(uint256 => Tx) txList;

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

    function getAddCandidateSignerCount(address addr)
        external
        view
        returns (uint8)
    {
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

    function transfer(address payable to, uint256 value) external {
        require(owners[msg.sender], "only owners can do this");
        require(address(this).balance >= value, "balance not enough");
        txNum++;
        txList[txNum].signerCount = 1;
        txList[txNum].signed[msg.sender] = true;
        txList[txNum].to = to;
        txList[txNum].value = value;
        emit BuildETHTx(msg.sender, txNum);
    }

    function confirmTx(uint256 id) external payable {
        require(owners[msg.sender], "only owners can do this");
        require(txList[id].signerCount != 0, "tx is no exist");
        require(!txList[id].send, "tx already sended");
        require(!txList[id].signed[msg.sender], "already signed");
        require(address(this).balance >= txList[id].value, "balance not enough");
        emit ApproveETHTx(msg.sender, id);
        txList[id].signerCount++;
        txList[txNum].signed[msg.sender] = true;
        if (txList[id].signerCount >= requireMinimum) {
            (txList[id].to).transfer(txList[id].value);
            txList[id].send = true;
            emit SendETHTx(msg.sender, id);
        }
    }

    function getTx(uint256 id)
        external
        view
        returns (
            address to,
            uint256 value,
            bool send,
            uint8 signerCount
        )
    {
        return (
            txList[id].to,
            txList[id].value,
            txList[id].send,
            txList[id].signerCount
        );
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}
