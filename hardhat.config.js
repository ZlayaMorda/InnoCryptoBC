require('@openzeppelin/hardhat-upgrades')
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.12",
    defaultNetwork: "hardhat",
    networks: {
        ropsten: {
            url: process.env.INFURA_API_KEY,
            accounts: [process.env.PRI_KEY],
        },
    },
    etherscan: {
        apiKey: process.env.API_KEY,
    }
};
