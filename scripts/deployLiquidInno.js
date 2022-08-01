const { ethers } = require("hardhat")

async function main() {
    const LiquidInno = await ethers.getContractFactory("LiquidInno")
    const liquidInno = await LiquidInno.deploy()
    await liquidInno.deployed()

    console.log("token deployed to address", liquidInno.address)
}

main()
.then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
