const HDWalletProvider = require('truffle-hdwallet-provider');

module.exports = {

  networks: {
    development: {
     host: "127.0.0.1",    
     port: 7545,            
     network_id: "*",       // Any network (default: none)
    },

    rinkeby: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://rinkeby.infura.io/" + process.env.INFURA_API_KEY),
      network_id: 1,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    }
  },

  compilers: {
    solc: {
      version: "0.4.24",
    }
  }
}
