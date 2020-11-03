const { use, expect } = require("chai")
const { solidity } = require("ethereum-waffle")
use(solidity)

describe("ETH", () => {
  let multisign
  let addr1
  let addr2
  let addr3
  let addr4

  beforeEach(async function () {
    [addr1, addr2, addr3, addr4] = await ethers.getSigners()
    multisign = await (await ethers.getContractFactory("Multisign")).deploy()
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