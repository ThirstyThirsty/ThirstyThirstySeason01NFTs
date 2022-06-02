// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre, { ethers } from 'hardhat';
import {
  OS_PROXY_ADDR,
  MERKLE_ROOT,
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
    false, // isMintStarted => false, so contract launches with goldlist minting only
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
