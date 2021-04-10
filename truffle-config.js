const HDWalletProvider = require('@truffle/hdwallet-provider')
const dotenv = require('dotenv');
dotenv.config('./env');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard BSC port (default: none)
      network_id: "*",       // Any network (default: none)
    },
	hecotest: {
      provider: () => {
        return new HDWalletProvider(process.env.HECO_TEST_MNEMONIC, process.env.HECO_TEST_RPC_URL)
      },
      network_id: '*',
      skipDryRun: true,
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      //optimizer: {
      //  enabled: true,
      //  runs: 200
      //},
      //evmVersion: "petersburg",
      version: "0.6.6"
    }
  }
}