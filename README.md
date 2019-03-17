# Token ERC721

Like the ERC20 standard, tokens implementing the ERC721 standard are used to trade digital assets. The main difference lies in their Non-Fungibility (NFT) that means each token is unique.

Here we modeled an IFCE breeding register and since each animal is unique, ERC721 Token is a good choice to identify them.

For our token ERC721, we used **[OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-solidity)** which is a library of secured and vetted smart contracts

### [Openzeppelin](https://github.com/OpenZeppelin/openzeppelin-solidity)

    npm i openzeppelin-solidity

## Environment - Arch Linux

### [Metamask](https://metamask.io/)

#### Chrome extension allowing us to connect to the Ethereum mainnet and testnets (Ropsten, Rinkeby, Kovan)

Just install it like any other chrome extension

### [Ganache](https://truffleframework.com/) : Local blockchain

We just need to create the package by taking it on the AUR

    git clone https://aur.archlinux.org/ganache.git
    makepkg -s
    sudo pacman -U --noconfirm file.pkg.tar.xz

### [Truffle](https://truffleframework.com/)

#### Environment that allows us to test smart contracts

We use the truffle@4.1.15 version (use the one you want)

    npm i -g truffle@4.1.15

#### Usage with Ganache:

    truffle compile
    truffle migrate
    truffle migrate --reset if contracts have already been migrated once

#### To interact with our contracts with the **[Web3.js](https://github.com/ethereum/wiki/wiki/JavaScript-API)** library

    truffle develop or truffle console

## Demonstration

**Get Ganache accounts:**

    accounts = web3.eth.accounts

By default, accounts[0] is the address deploying our contracts that means it is the contracts owner

### Farm

**Get instance**

    Farm.deployed().then(instance => farm = instance)

**Register breeder**

    farm.registerBreeder(accounts[1])
    farm.isBreeder(accounts[1])
    > true

**Declare animal**

    farm.declareAnimal(...)

**Declare animal from specific account (needs to be breeder)**

    farm.declareAnimal(..., { from: accounts[1] })

**Breeding**

Need to approve a specific address to use our token. Say that token #1 belongs to accounts[0] (owner) and token #2 belongs to accounts[1]

Approve accounts[1] to breed with our animal (assume they are of different sex).

    ERC721.deployed().then(instance => erc721 == instance)
    erc721.approve(accounts[1], 1)
    erc721.getApproved(1)
    > accounts[1]
    farm.breedAnimals(2, 1, { from: accounts[1] })
    > create a new animal and token assigned to accounts[1]

**Auction**

For the auction, we chose to not use the token approvement to allow someone to bid on our animal. Indeed, we felt it was appropriate to let everyone bid on our animal. There was also the possibility to use a mapping (uint => bool) _tokenApprovedForEveryone in the ERC721 contract but we didn't find it relevant. **Same for Arena**.

    farm.createAuction(1, 2000)
    farm.bidOnAuction(1, 2000)

After the delay (2 days) the last bidder can claim the auctioned animal. Say that it is accounts[1]

    farm.claimAuction(1, {from: accounts[1] })

The animal #1 and token #1 will be transfered to accounts[1] as well as the funds (Token ERC20) from the last bidder to the seller

**Similar logic for other functions**

# Rinkeby - Infura

On metamask, select Rinkeby and get some ether on a **[faucet](https://faucet.rinkeby.io/)**. 

In order to connect to the Rinkeby testnet, we'll use **[Infura](https://infura.io)**. First, we need to **[register](https://infura.io/signup)** in order to create our API endpoint.
Now that we have our endpoint, we can make the connection with the Rinkeby testnet.

But since it requires our wallet mnemonic and our Infura API key, for security reasons we'll hide them
We use the npm package **[dotenv](https://www.npmjs.com/package/dotenv)** to read .env files.

    npm i dotenv

Create a .env file and store the mnemonic and the Infura API key

#### Install HDWallet Provider

    npm i --save truffle-hdwallet-provider

#### Configure truffle in order to connect to Rinkeby

    rinkeby: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://rinkeby.infura.io/" + process.env.INFURA_API_KEY),
      network_id: 1,       // Rinkeby's id
      gas: 5500000,        
      confirmations: 2,    
      timeoutBlocks: 200,  
      skipDryRun: true     
    }

## Deploy contracts

Now that we have our contracts and the endpoint to Rinkeby, we can deploy our contracts.

    truffle compile
    truffle migrate --network rinkeby

To interact with our contracts, we also use truffle

    truffle console --network rinkeby

## Demonstration

Our crowdsale is based on breeders, that means only breeders can trade our Token/Animal
To register a breeder we need an instance of our Farm contract:

    Farm.deployed().then(instance => farm = instance)

Now that we have our instance, we can use functions/methods of this contract:

    farm.registerBreeder(<address>)
    farm.isBreeder(<address>)
    > true

To send an animal to an address

    farm.transferAnimal(<address>, 3)

Obviously, this is supposed that each condition is fulfilled (ownerOfAnimal(id), isBreedr(receiver) etc...)

Same logic for other functions.

*Note: < address> should be replaced by a real address. For example: "0x14e..."*