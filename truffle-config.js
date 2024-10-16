
module.exports = {


  networks: {

    development: {
     host: "localhost",     // Localhost (default: none)
     port: 8545,            // Standard Ethereum port (default: none)
     network_id: "*",      // Any network (default: none)
    },
   
    advanced: {
      websocket: true         
    },

  },


  // Configure your compilers
  contracts_build_directory: "assets/src/abis/",

  compilers: {
    solc: {
      version: "0.8.19",      
      settings: {     
       optimizer: {
         enabled: true,
         runs: 200
       }
      }
    }
  },

};
