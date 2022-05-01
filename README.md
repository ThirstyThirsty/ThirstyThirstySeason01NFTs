# ThirstyThirsty NFTs - Season 1 Smart Contract

Smart contract for Thirsty Thirsty's first NFT. It is used in conjunction with a [minting website](https://thirstythirsty-nft.herokuapp.com) with a [dedicated repository](https://github.com/ThirstyThirsty/ThirstyThirstySeason01Website).

## Installation

The project runs on [Hardhat](https://hardhat.org/). Install dependencies with following command:

```
npm install # or yarn install
```

## Usage

### Synopsis

> How many different tier and artworks are we planning to use, and how are they dispatched among NFTs?

There are 3 NFT tiers with different pricing, with the same artwork in 3 different colors to distinguish each other.

- **Tier 1 “Cellar”** - `270 units at $1,000 each` (ETH price TBD)

- **Tier 2 “Table”** - `518 units`, including:

  - Normal (mintable by anyone) - `418 units at $500 each` (ETH price TBD)

  - "Goldlist" (using a Merkle tree) for our Discord members - `100 at $200 each` (ETH price TBD)

- **Tier 3 “Frens & Fam”** - `50 units, free (airdropped)`

For the purpose of this collection, the same smart contract is deployed into 4 different instances:
https://github.com/ThirstyThirsty/ThirstyThirstySeason01NFTs
- one for the "Cellar" tier;
- one for the "Table" tier;
- one for the "Table" tier on a goldlist (at cheaper minting price);
- one for the "Friends & Fam" tier (airdropped).

The rationale for serving different contracts is to adhere to the ["simplicity" development best-practice](https://consensys.github.io/smart-contract-best-practices/general-philosophy/simplicity/) for Ethereum.

##### About the goldlist

The allow-list ("goldlist") for a chunk of the "Table" tier requires a specific technical treatment that is detailed under the **Development** section of this README.

## Development

### Test suite

Contracts were written using [TDD](https://en.wikipedia.org/wiki/Test-driven_development). To run the test suite, use the following command:
```
npx hardhat test
```

### Local node development
To run the local Hardhat (local) Ethereum node:
```
npx hardhat node
```

The project is setup to enable using MetaMask on the Hardhat node. To do so, configure MetaMask to display test networks (**Settings > Advanced Settings > Display testnets**), and switch active network on MetaMask to **Localhost 8545**.

## Goldlist

There is an allow-list ("goldlist") system for the "Table" tier.

It has a list of wallets with the privilege to mint a chunk of that tier at a lower price point. For performance and security purposes, _we are never storing this list anywhere on this application._ Not on the website's database, nor on the smart contract. Ever.

Instead, we are using a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree), which is a useful cryptographic data structure that helps doing the following process for our purpose:

1. Turn the goldlist of wallets (public keys) using a Merkle Tree algorithm.
2. Store the hash called "Merkle root" in the site's DB. The "Merkle root" is like a signature of this specific tree.
3. Use a specific Merkle tree algo to compare any wallet's public key to the "Merkle root".
4. Comparison will yield a positive answer if the public key belongs to the tree (i.e. the wallet address is in the goldlist), a negative otherwise, without ever giving away the original list.

In our implementation, we use a dedicated script to generate a "Merkle root" for the goldlist.

#### Generate a new Merkle root for the goldlist

1. In the `scripts` directory, create a `goldlist.json` file based on `scripts/goldfile.example.json`:

```
cp ./scripts/goldlist.example.json ./scripts/goldlist.json
```

> The `goldlist.json` is ignored by Git to prevent accidentally storing sensitive data to the repo.

2. Update the `goldlist.json` file. The file should contain a JSON array of strings, with each string being a public key (address) for a goldlisted wallet.

3. Run the `merkle-root` script to generate a hash from the list in the `goldlist.json` file:

```
npx hardhat run scripts/merkle-root.ts
```

4. The console will print out a few things, ending the new "Merkle root":

```
Merkle root generated: 0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade
```

5. Copy the hash (in this example, `0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade`) and use.

6. In the minting website, update the environment variable `MERKLE_ROOT` to use this hash as value.

## Deployment of smart contract

### Development (Hardhat node)

```
# Create a .env file from the .env.example file.
cp .env.example .env

# Add your deployment private key in the .env as value for the `PRIVATE_KEY` variable.

# Then deploy your contracts by running the following command:
npx hardhat run scripts/deploy.ts --network localhost
```

> The .env is ignored by git so that your private key never leaves your computer, but stay safe and use a throwaway dev account when you're working!

The script above will create and deploy the four contracts, and display their addresses in the console. The `network` options enables specifying where to deploy. For details on the contract instance options (e.g. supply number, mint price, goldlists), see `script/deploy.ts`.

For more info on the possible network to deploy to, please read `hardhat.config.ts`.

### Deployment on testnet (Rinkeby)

Edit the `.env` file `RINKEBY_URL` variable with the relevant information to connect to a Rinkeby node through a provider. Then run the command mentioned above specifying the appropriate network:

```
npx hardhat run scripts/deploy.ts --network rinkeby
```

## Contract addresses

Here are the up-to-date contract addresses on Rinkeby.

### Rinkeby

```
- "Cellar"        0x2011bDd9de56e3ad9b730948e4179df474eeE37E
- "Table"         0xc6C643944519350F2b13365C17210118E7087E2a
- "Table Gold"    0xcBcf0BdA4b151bf86912f6534f958901D130486b
- "Frens & Fam"   0x4209948b3B1f0ce21E0dcCFaAcF4ABA3E2B913F6
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
