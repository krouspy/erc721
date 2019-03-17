const SafeMath = artifacts.require("SafeMath");
const Counters = artifacts.require("Counters");
const ERC721 = artifacts.require("ERC721");
const ERC20 = artifacts.require("ERC20");
const Farm = artifacts.require("Farm");
const Arena = artifacts.require("Arena");

const name = "FarmCoin";
const ticker = "FC";
const totalSupply = 10**30;
const decimals = 8;

module.exports = function(deployer, network, accounts) {

  if (network === "development") {
    return deployer
    .then(() => deployer.deploy(SafeMath))
    .then(() => deployer.link(SafeMath, Counters))
    .then(() => deployer.link(SafeMath, ERC20))
    .then(() => deployer.link(SafeMath, ERC721))
    .then(() => deployer.link(SafeMath, Farm))
    .then(() => deployer.link(SafeMath, Arena))
    .then(() => deployer.deploy(Counters))
    .then(() => deployer.deploy(ERC20, name, ticker, totalSupply, decimals))
    .then(() => deployer.link(Counters, ERC721))
    .then(() => deployer.deploy(ERC721))
    .then(() => deployer.deploy(Farm, ERC721.address, ERC20.address))
    .then(() => deployer.deploy(Arena, Farm.address, ERC721.address, ERC20.address))
    .then(() => Farm.deployed())
    .then(farmInstance => {
      farmInstance.registerBreeder(accounts[0]);
      farmInstance.registerBreeder(accounts[1]);
      farmInstance.macgyver(30, true, true, false);
      farmInstance.macgyver(20, false, true, true, { from: accounts[1] });
    })
    .then(() => ERC20.deployed())
    .then(erc20Instance => {
      erc20Instance.transfer(accounts[1], totalSupply / 10);
    })

  }
  
  if (network === "rinkeby") {
    return deployer
    .then(() => deployer.deploy(SafeMath))
    .then(() => deployer.link(SafeMath, Counters))
    .then(() => deployer.link(SafeMath, ERC20))
    .then(() => deployer.link(SafeMath, ERC721))
    .then(() => deployer.link(SafeMath, Farm))
    .then(() => deployer.link(SafeMath, Arena))
    .then(() => deployer.deploy(Counters))
    .then(() => deployer.deploy(ERC20, name, ticker, totalSupply, decimals))
    .then(() => deployer.link(Counters, ERC721))
    .then(() => deployer.deploy(ERC721))
    .then(() => deployer.deploy(Farm, ERC721.address, ERC20.address))
    .then(() => deployer.deploy(Arena, Farm.address, ERC721.address, ERC20.address))
  }
};
