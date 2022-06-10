// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre, { ethers } from 'hardhat';
import {
  NAME,
  SYMBOL,
  METADATA_BASE_URI
} from '../utils/constants'

import {
  tierCellar,
  tierTable,
  tierTableGold,
  tierFrens
} from './tiers';

// OS_PROXY_ADDR is taken from the env variable set in the package script
// Set to mainnnet address by default.
const OS_PROXY_ADDR = process.env.OS_PROXY_ADDR || '0xa5409ec958c83c3f309868babaca7c86dcb077c1';

const MERKLE_ROOT = process.env.MERKLE_ROOT;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run('compile')

  const Factory = await ethers.getContractFactory('ThirstyThirstySeason01')

  const contract = await Factory.deploy(
    NAME,
    SYMBOL,
    METADATA_BASE_URI,
    OS_PROXY_ADDR,
    tierCellar,
    tierTable,
    tierTableGold,
    tierFrens,
    MERKLE_ROOT
  )

  await contract.deployed()

  console.log("\n")
  console.log('`Thirsty Thirsty` contract deployed to:', contract.address)
  console.log("\n")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
