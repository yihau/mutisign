async function main() {
  const Token = await ethers.getContractFactory("Multisign")
  console.log("Deploying contract...")

  // 部署前需要修改這兩個參數
  let initOwners = []  // owner address array
  let initMinimumRequired = 0  // require mininum

  const token = await Token.deploy(initOwners, initMinimumRequired);
  await token.deployed()
  console.log("contract deployed to:", token.address)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })