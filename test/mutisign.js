const { use, expect } = require("chai")
const { solidity } = require("ethereum-waffle")
use(solidity)

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
