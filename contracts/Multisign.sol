// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

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
    address token;
}

contract Multisign {

    using SafeERC20 for IERC20;

    event ReceiveETH(address indexed sender, uint256 indexed num);
    event NominateAddedOwner(address indexed sender, address indexed candidate);
    event AddOwner(address indexed candidate);
    event NominateRemoveOwner(address indexed sender, address indexed candidate);
    event RemoveOwner(address indexed candidate);
    event BuildTx(address indexed sender, uint256 TxID);
    event ApproveTx(address indexed sender, uint256 TxID);
    event SendTx(address indexed sender, uint256 TxID);

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

    function transfer(address payable to, uint256 value, address token) external {
        require(owners[msg.sender], "only owners can do this");
        if(token != address(0)) {
          require(IERC20(token).balanceOf(address(this)) >= value, "balance not enough");
        } else {
          require(address(this).balance >= value, "balance not enough");
        }
        txNum++;
        txList[txNum].signerCount = 1;
        txList[txNum].signed[msg.sender] = true;
        txList[txNum].to = to;
        txList[txNum].value = value;
        txList[txNum].token = token;
        emit BuildTx(msg.sender, txNum);
    }

    function confirmTx(uint256 id) external payable {
        require(owners[msg.sender], "only owners can do this");
        require(txList[id].signerCount != 0, "tx is no exist");
        require(!txList[id].send, "tx already sended");
        require(!txList[id].signed[msg.sender], "already signed");
        if(txList[id].token != address(0)) {
          require(IERC20(txList[txNum].token).balanceOf(address(this)) >= txList[id].value, "balance not enough");
        } else {
          require(address(this).balance >= txList[id].value, "balance not enough");
        }
        emit ApproveTx(msg.sender, id);
        txList[id].signerCount++;
        txList[id].signed[msg.sender] = true;
        if (txList[id].signerCount >= requireMinimum) {
            if(txList[id].token != address(0)) {
              IERC20(txList[id].token).safeTransfer(txList[id].to, txList[id].value);
            } else {
              (txList[id].to).transfer(txList[id].value);
            }
            txList[id].send = true;
            emit SendTx(msg.sender, id);
        }
    }

    function getTx(uint256 id)
        external
        view
        returns (
            address to,
            uint256 value,
            bool send,
            uint8 signerCount,
            address token
        )
    {
        return (
            txList[id].to,
            txList[id].value,
            txList[id].send,
            txList[id].signerCount,
            txList[id].token
        );
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}
