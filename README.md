# ThirstyThirsty NFT 01 - Smart Contract "Inaugural, 2021 Harvest"

Smart contract for Thirsty Thirsty's first NFT. It is used in conjunction with a [minting website](https://thirstythirsty-nft.herokuapp.com) with a [dedicated repository](https://github.com/ThirstyThirsty/ThirstyThirstySeason01Website).

Made with ❤️

## Installation

The project runs on [Hardhat](https://hardhat.org/). Install dependencies with following command:

```
npm install # or yarn install
```

## Usage

### Synopsis

#### Dispatch

There are 3 mintable NFT types — 3 tiers — with different pricing.

- **Tier 1 “Cellar”** - `270 units at 0.4 ETH`

- **Tier 2 “Table”** - `518 units`, including:

  - Regular `418 units at 0.2 ETH`

  - Goldlist for our Discord members - `100 at 0.1 ETH`

- **Tier 3 “Frens & Fam”** - `50 units, free (airdropped)`

#### Goldlist?

The allow-list ("goldlist") for a chunk of the "Table" tier requires a specific technical treatment that is detailed under the **Development** section of this README.

## Development

### Test suite

Contracts were written using [TDD](https://en.wikipedia.org/wiki/Test-driven_development). To run the test suite, use the following command:
```
npm test
```

### Local node development
To run the local Hardhat (local) Ethereum node:
```
npm dev
```

The project is setup to enable using MetaMask on the Hardhat node. To do so, configure MetaMask to display test networks (**Settings > Advanced Settings > Display testnets**), and switch active network on MetaMask to **Localhost 8545**.

## Goldlist

There is an allow-list ("goldlist") system for the "Table" tier.

Wallets in this list can mint are allocated a portion of that tier at a lower price point.
We are using a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) to handle list verification.

Goldlist minting happens through the `mintGold(bytes32[])` method of the contract, taking a merkle proof as argument (see implementation on the [mint website repo](https://github.com/ThirstyThirsty/ThirstyThirstySeason01Website)).

**Everytime you want to update the goldlist, you need to follow the instructions below.**

### Generate a new Merkle tree for the goldlist

1. In the `scripts` directory, create a `goldlist.json` file based on `scripts/goldfile.example.json`:

```
cp ./scripts/goldlist.example.json ./scripts/goldlist.json
```

> The `goldlist.json` is ignored by Git to prevent accidentally storing sensitive data to the repo.

2. Update the `goldlist.json` file. The file should contain a JSON array of strings, with each string being a public key (address) for a goldlisted wallet.

3. Run the `merkle-root` script to generate a hash from the list in the `goldlist.json` file:

```
npm run goldlist
```

4. The console will print out a few things, including a line mentioning a "Merkle root":

```
Merkle root generated: 0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade
```

5. Copy the hash (in this example, `0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade`).

6. Update the Merkle root stored in the smart contract instances deployed on various networks (see addresses at the end of the README) using the `setMerkleRoot` method.

7. The mint website has its own instruction in regards to implementing the Goldlist. After you're through with the steps above, and if you're using the minting website as well, check out the [repo](https://github.com/ThirstyThirsty/ThirstyThirstySeason01Website) for the final instructions.

## Deployment of smart contract

Create a `.env` file from the `.env.example` file.

> The .env is ignored by git so that your private key never leaves your computer, but stay safe and use a throwaway dev account when you're working!

```
cp .env.example .env
```

### Deploy on localhost (Hardhat node)

Run the following command:

```
npm run deploy:localhost
```

### Deployment on testnet (Rinkeby)

Edit the `.env` file with:

- a `RINKEBY_URL` variable with the relevant information to connect to a Rinkeby node through a provider
- a `PRIVATE_KEY_RINKEBY` variable containing the private key of the deployer account (the `.env` file is **not** committed)

Then run the following command:

```
npm run deploy:rinkeby
```

### Deployment on mainnet

Edit the `.env` file with:

- a `MAINNET_URL` variable with the relevant information to connect to a Rinkeby node through a provider
- a `PRIVATE_KEY_MAINNET` variable containing the private key of the deployer account (the `.env` file is **not** committed)

Then run the following command:

```
npm run deploy:mainnet
```

## Verify smart contract on Etherscan

You can automate the cumbersome task of veryfing the smart contract code on Etherscan, making it available for review to the public with a nice little green checkbox.

To do so, copy the address where the contract instance has been deployed, either on Rinkeby or the mainnet. It is printed in the console as a final success message when you run the `deploy:` commands.

Then paste the address at the end of the following commands:

```
# Testnet
npm run verify:rinkeby <RINKEBY_CONTRACT_ADDRESS>

# Mainnet
npm run verify:mainnet <MAINNET_CONTRACT_ADDRESS>
```

## Withdraw smart contract funds

### Withdrawal from primary sales

Funds accumulated on the smart contract after primary sales can be transfered to the contract's `owner` using the `withdraw()` method. It takes no argument and transfers all remaining funds to the message sender (which is the _de facto_ `owner`, as this method is activable by owner only).

### Secondary sales royalties

Secondary sales are handled by platforms directly.

[OpenSea](https://opensea.io/) will send the funds to the `owner` after platforms fees.

The smart contract implements [Rarible](https://rarible.com)'s royalties specifications to set a **20%** royalty split for the `owner`, as well as the [ERC2981 NFT Royalties Standard](https://eips.ethereum.org/EIPS/eip-2981). The latter informs [Mintable](https://mintable.app) that **20%** of the resale is sent to the owner and hopefully, as the spec becomes enforced by more and more platforms, it makes the royalties management for this contract future-proof.

## Contract addresses

Here are the up-to-date contract addresses on various Ethereum networks.

```
- Rinkeby        0x4413Ce6eed4e5C5a79D4a4547d3EB353F449dFc1
- Mainnet        TBD
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
