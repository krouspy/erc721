const SafeMath = artifacts.require("SafeMath");
const Counters = artifacts.require("Counters");
const ERC721 = artifacts.require("ERC721");
const ERC20 = artifacts.require("ERC20");
const Farm = artifacts.require("Farm");

const name = "FarmCoin";
const ticker = "FC";
const totalSupply = 10**30;
const decimals = 8;

module.exports = function(deployer) {
  return deployer
  .then(() => deployer.deploy(SafeMath))
  .then(() => deployer.link(SafeMath, Counters))
  .then(() => deployer.link(SafeMath, ERC20))
  .then(() => deployer.link(SafeMath, ERC721))
  .then(() => deployer.link(SafeMath, Farm))
  .then(() => deployer.deploy(Counters))
  .then(() => deployer.deploy(ERC20, name, ticker, totalSupply, decimals))
  .then(() => deployer.link(Counters, ERC721))
  .then(() => deployer.deploy(ERC721))
  .then(() => deployer.deploy(Farm, ERC721.address, ERC20.address));
};
