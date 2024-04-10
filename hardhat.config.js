require("@nomiclabs/hardhat-waffle");

// require('@openzeppelin/hardhat-upgrades');

// require("@nomiclabs/hardhat-etherscan");

// require("@nomiclabs/hardhat-web3");

const { PRIVATEKEY, APIKEY } = require("./pvkey.js")

module.exports = {
  // latest Solidity version
  paths: {
    sources: "./contracts",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.13",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ]
  },

  networks: {

    bsc: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: PRIVATEKEY
    },

    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: PRIVATEKEY
    },


    op: {
      url: "https://mainnet.optimism.io",
      chainId: 10,
      accounts: PRIVATEKEY
    },

    ftmt: {
      url: "https://rpc.testnet.fantom.network",
      chainId: 4002,
      accounts: PRIVATEKEY
    },
    IoTex_testnet: {
      url: "https://babel-api.testnet.iotex.io",
      chainId: 4690,
      accounts: PRIVATEKEY,
      gasPrice: 1000000000000
    },
    opBNB_testnet: {
      url: "https://opbnb-testnet-rpc.bnbchain.org",
      chainId: 5611,
      accounts: PRIVATEKEY,
      //gasPrice: 500000000
    },
    era_testnet: {
      url: "https://sepolia.era.zksync.dev",
      chainId: 300,
      accounts: PRIVATEKEY,
      gasPrice: 500000000
    },
    
    hardhat: {
      forking: {
          url: "https://bsc-dataseed1.binance.org",
          chainId: 56,
      },
      //accounts: []
    }
  
  },

  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: APIKEY
  },

  mocha: {
    timeout: 100000000
  }

}