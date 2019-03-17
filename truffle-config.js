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
      network_id: 1,       // Rinkeby's id
      gas: 5500000,        
      confirmations: 2,    
      timeoutBlocks: 200,  
      skipDryRun: true     
    }
  },

  compilers: {
    solc: {
      version: "0.4.24",
    }
  }
}
