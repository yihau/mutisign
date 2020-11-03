const { use, expect } = require("chai")
const { solidity } = require("ethereum-waffle")
use(solidity)

const zeroAddress = "0x0000000000000000000000000000000000000000";

describe("Multisign", () => {

  describe("Contract Init", () => {
    it("should revert when require minimum greater than owners count", async () => {
      [addr1, addr2, addr3] = await ethers.getSigners()
      initOwners = [addr1.address, addr2.address, addr3.address]
      initRequireMinimum = 10
      await expect((await ethers.getContractFactory("Multisign")).deploy(initOwners, initRequireMinimum)).
        to.be.revertedWith("owners count should greater than or equal to require minimum")
    })
    it("should match between contract variable and init args", async () => {
      [addr1, addr2, addr3, addr4] = await ethers.getSigners()
      initOwners = [addr1.address, addr2.address, addr3.address]
      initRequireMinimum = 2
      multisign = await (await ethers.getContractFactory("Multisign")).deploy(initOwners, initRequireMinimum)
      expect(await multisign.owners(addr1.address)).to.be.equal(true)
      expect(await multisign.owners(addr2.address)).to.be.equal(true)
      expect(await multisign.owners(addr3.address)).to.be.equal(true)
      expect(await multisign.owners(addr4.address)).to.be.equal(false)
      expect(await multisign.requireMinimum()).to.be.equal(initRequireMinimum)
      expect(await multisign.ownersCount()).to.be.equal(3)
    })
  })

  describe("Add Owner", () => {
    let multisign
    let addr1
    let addr2
    let addr3
    let addr4
    let addr5
    beforeEach(async function () {
      [addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners()
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
    })

    it("should revert when nominee is not in owner group", async () => {
      await expect(multisign.connect(addr4).addOwner(addr5.address)).
        to.be.revertedWith("only owners can do this")
    })
    it("should revert when candidate is in owner group", async () => {
      await expect(multisign.connect(addr3).addOwner(addr2.address)).
        to.be.revertedWith("already is one of owner")
    })
    it("should add a candidate", async () => {
      await expect(multisign.connect(addr3).addOwner(addr5.address)).
        to.emit(multisign, 'NominateAddedOwner').withArgs(addr3.address, addr5.address)
      expect(await multisign.getAddCandidateSignerCount(addr5.address)).to.be.equal(1)
    })
    it("should add a owner", async () => {
      await expect(multisign.connect(addr3).addOwner(addr5.address)).
        to.emit(multisign, 'NominateAddedOwner').withArgs(addr3.address, addr5.address)
      expect(await multisign.getAddCandidateSignerCount(addr5.address)).to.be.equal(1)
      await expect(multisign.connect(addr2).addOwner(addr5.address)).
        to.emit(multisign, "AddOwner").withArgs(addr5.address)
      expect(await multisign.getAddCandidateSignerCount(addr5.address)).to.be.equal(0)
      expect(await multisign.owners(addr5.address)).to.be.equal(true)
      expect(await multisign.ownersCount()).to.be.equal(4)
    })
    it("should revert when nominate same candidate twice by same owner", async () => {
      await multisign.connect(addr3).addOwner(addr5.address)
      await expect(multisign.connect(addr3).addOwner(addr5.address)).
        to.be.revertedWith("already nominate this candidate")
    })
  })

  describe("Remove Owner", () => {
    let multisign
    let addr1
    let addr2
    let addr3
    let addr4
    let addr5
    beforeEach(async function () {
      [addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners()
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
    })

    it("should revert when nominee is not in owner group", async () => {
      await expect(multisign.connect(addr4).removeOwner(addr5.address)).
        to.be.revertedWith("only owners can do this")
    })
    it("should revert when candidate is not in owner group", async () => {
      await expect(multisign.connect(addr3).removeOwner(addr5.address)).
        to.be.revertedWith("address is not one of owner")
    })
    it("should add a remove candidate", async () => {
      await expect(multisign.connect(addr3).removeOwner(addr2.address)).
        to.emit(multisign, 'NominateRemoveOwner').withArgs(addr3.address, addr2.address)
      expect(await multisign.getRemoveCandidateSignerCount(addr2.address)).to.be.equal(1)
    })
    it("should remove a owner", async () => {
      await expect(multisign.connect(addr3).removeOwner(addr2.address)).
        to.emit(multisign, 'NominateRemoveOwner').withArgs(addr3.address, addr2.address)
      expect(await multisign.getRemoveCandidateSignerCount(addr2.address)).to.be.equal(1)
      await expect(multisign.connect(addr1).removeOwner(addr2.address)).
        to.emit(multisign, 'RemoveOwner').withArgs(addr2.address)
      expect(await multisign.getRemoveCandidateSignerCount(addr2.address)).to.be.equal(0)
      expect(await multisign.owners(addr2.address)).to.be.equal(false)
      expect(await multisign.ownersCount()).to.be.equal(2)
    })
    it("should revert when owner not enough", async () => {
      await multisign.connect(addr1).removeOwner(addr3.address)
      await multisign.connect(addr2).removeOwner(addr3.address)
      await expect(multisign.connect(addr1).removeOwner(addr2.address)).to.be.revertedWith("owner not enough")
    })

    it("should revert when nominate same candidate twice by same owner", async () => {
      await multisign.connect(addr3).removeOwner(addr2.address)
      await expect(multisign.connect(addr3).removeOwner(addr2.address)).
        to.be.revertedWith("already nominate this candidate")
    })
  })

  describe("Transfer ETH", () => {
    let multisign
    let addr1
    let addr2
    let addr3
    let addr4
    beforeEach(async function () {
      [addr1, addr2, addr3, addr4] = await ethers.getSigners()
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
    })
    it("should revert when not owner try to transfer", async () => {
      await expect(multisign.connect(addr4).transfer(addr4.address, 100, zeroAddress)).
        to.be.revertedWith("only owners can do this")
    })
    it("should revert when contract balance not enough", async () => {
      await expect(multisign.connect(addr1).transfer(addr4.address, 100, zeroAddress)).
        to.be.revertedWith("balance not enough")
    })
    it("should add a tx", async () => {
      await addr1.sendTransaction({ to: multisign.address, value: 100 })
      await expect(multisign.connect(addr1).transfer(addr4.address, 100, zeroAddress)).
        to.emit(multisign, 'BuildTx').withArgs(addr1.address, 1)
      let tx = await multisign.getTx(1)
      expect(tx.to).to.equal(addr4.address)
      expect(tx.value).to.equal(100)
      expect(tx.send).to.equal(false)
      expect(tx.signerCount).to.equal(1)
      expect(tx.token).to.equal(zeroAddress)
    })
  })

  describe("Transfer ERC20Token", () => {
    let multisign
    let token
    let addr1
    let addr2
    let addr3
    let addr4
    beforeEach(async function () {
      [addr1, addr2, addr3, addr4] = await ethers.getSigners()
      token = await (await ethers.getContractFactory("Token")).deploy("USDT", "USDT", 0, 100000)
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
    })
    it("should add a tx", async () => {
      await addr1.sendTransaction({ to: multisign.address, value: 100 })
      await token.connect(addr1).transfer(multisign.address, 100)
      await expect(multisign.connect(addr1).transfer(addr4.address, 100, token.address)).
        to.emit(multisign, 'BuildTx').withArgs(addr1.address, 1)
      let tx = await multisign.getTx(1)
      expect(tx.to).to.equal(addr4.address)
      expect(tx.value).to.equal(100)
      expect(tx.send).to.equal(false)
      expect(tx.signerCount).to.equal(1)
      expect(tx.token).to.equal(token.address)
    })
  })

  describe("Confirm Tx", () => {
    let multisign
    let addr1
    let addr2
    let addr3
    let addr4
    beforeEach(async function () {
      [addr1, addr2, addr3, addr4] = await ethers.getSigners()
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
      await addr1.sendTransaction({ to: multisign.address, value: 100 })
      await multisign.connect(addr1).transfer(addr4.address, 100, zeroAddress)
    })
    it("should revert when not owner try to confirm", async () => {
      await expect(multisign.connect(addr4).confirmTx(1)).
        to.be.revertedWith("only owners can do this")
    })
    it("should revert when tx not exist", async () => {
      await expect(multisign.connect(addr2).confirmTx(2)).
        to.be.revertedWith("tx is no exist")
    })
    it("should revert when already confirm", async () => {
      await expect(multisign.connect(addr1).confirmTx(1)).
        to.be.revertedWith("already signed")
    })
    it("should emit approve event", async () => {
      await expect(multisign.connect(addr2).confirmTx(1)).
        to.emit(multisign, 'ApproveTx').withArgs(addr2.address, 1)
    })
    it("should emit send event", async () => {
      await expect(multisign.connect(addr2).confirmTx(1)).
        to.emit(multisign, 'SendTx').withArgs(addr2.address, 1)
    })
    it("balance should match", async () => {
      await expect(() => multisign.connect(addr2).confirmTx(1)).
        to.be.changeEtherBalances([multisign, addr4], [-100, 100])
    })
  })

  describe("Confirm ERC20 Tx", () => {
    let multisign
    let token
    let addr1
    let addr2
    let addr3
    let addr4
    beforeEach(async function () {
      [addr1, addr2, addr3, addr4] = await ethers.getSigners()
      token = await (await ethers.getContractFactory("Token")).deploy("USDT", "USDT", 0, 100000)
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
      await token.connect(addr1).transfer(multisign.address, 100)
      await multisign.connect(addr1).transfer(addr4.address, 100, token.address)
    })
    it("balance should match", async () => {
      await expect(() => multisign.connect(addr2).confirmTx(1)).
        to.be.changeTokenBalances(token, [multisign, addr4], [-100, 100])
    })
  })

  describe("ETH", () => {
    let multisign
    let addr1
    let addr2
    let addr3
    let addr4

    beforeEach(async function () {
      [addr1, addr2, addr3, addr4] = await ethers.getSigners()
      multisign = await (await ethers.getContractFactory("Multisign")).deploy([addr1.address, addr2.address, addr3.address], 2)
    })

    it("should success when send eth to contract", async () => {
      await expect(() => addr1.sendTransaction({ to: multisign.address, value: 10 })).
        to.be.changeEtherBalances([addr1, multisign], [-10, 10])
    })

    it("should emit event when send eth to contract", async () => {
      await expect(addr1.sendTransaction({ to: multisign.address, value: 10 }))
        .to.emit(multisign, 'ReceiveETH')
        .withArgs(addr1.address, 10)
    })
  })
})
