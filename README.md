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

There are 3 mintable NFT types — 3 tiers — with different pricing.

- **Tier 1 “Cellar”** - `270 units at 0.4 ETH`

- **Tier 2 “Table”** - `518 units`, including:

  - Normal (mintable by anyone) - `418 units at 0.2 ETH`

  - "Goldlist" (using a Merkle tree) for our Discord members - `100 at 0.1 ETH`

- **Tier 3 “Frens & Fam”** - `50 units, free (airdropped)`

> What's the goldlist?

The allow-list ("goldlist") for a chunk of the "Table" tier requires a specific technical treatment that is detailed under the **Development** section of this README.

> Is there an enabling/disabling process for the mint?

The smart contract provides a boolean flag, `isMintStarted`, with a matching setter method, `setMintStarted(bool)` usable by the contract owner. When `isMintStarted` is `false`, only goldlisted-mints can happen. Call to the regular `mint` (non-gold) method will fail. **Call to the goldlist minting (`mintGold()`) will still be enabled no matter what.

There are also `pause`/`unpause` methods for the contract owner, acting as a classic ERC-721 contract fail-switch.

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

It has a list of wallets with the privilege to mint a chunk of that tier at a lower price point.
We are using a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) to handle list verification.

Goldlist minting happens through the `mintGold(bytes32[])` method of the contract, taking a merkle proof as argument (see implementation on the [mint website repo](#)).

Goldlisted users can mint at a cheaper price point, but they can also mint before others (non-gold) users. They can also mint when regular users can't (i.e. no matter the value of `isMintStarted`).

#### Generate a new Merkle tree for the goldlist

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

4. The console will print out a few things, including a line mentioning a "Merkle root":

```
Merkle root generated: 0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade
```

5. Copy the hash (in this example, `0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade`).

6. Update the Merkle root stored in the "Table (Goldlist)" instance deployed on various nets (see addresses at the end of the README) using the `setMerkleRoot` method of the contract.

The mint website has its own instruction in regards to implementing the Goldlist. After you're through with the steps above, and if you're using the minting website as well, check out the [repo](#) for the final instructions.

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

Here are the up-to-date contract addresses on various Ethereum networks.

```
- Rinkeby        TBD
- Mainnet        TBD
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
