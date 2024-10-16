const SupplyChain = artifacts.require("MyCoin");

module.exports = function (deployer) {
  deployer.deploy(SupplyChain);
};
