// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre, { ethers } from 'hardhat';
import { openSeaProxyRegistryAddress } from '../utils/constants'

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run('compile');

  const Factory = await ethers.getContractFactory('ThirstyThirstySeason01');
  const tierCellar = await Factory.deploy(
    'Thirsty Thirsty Season 1 - "Cellar"',
    'TT',
    '',
    openSeaProxyRegistryAddress,
    270,
    ethers.utils.parseEther('0.3'),
    ethers.utils.hexZeroPad('0x00', 32)
  );
  const tierTable = await Factory.deploy(
    'Thirsty Thirsty Season 1 - "Table"',
    'TT',
    '',
    openSeaProxyRegistryAddress,
    418,
    ethers.utils.parseEther('0.17'),
    ethers.utils.hexZeroPad('0x00', 32)
  );
  const tierTableGold = await Factory.deploy(
    'Thirsty Thirsty Season 1 - "Table" Goldlist',
    'TT',
    '',
    openSeaProxyRegistryAddress,
    100,
    ethers.utils.parseEther('0.07'),
    '0x31ee47f7fbec35a75a75ee71d0d72c71970c5cc8ecf2f7f5ec4e39a5f40adade', // CHANGE WITH MOST RECENT MERKLE ROOT
    // ethers.utils.hexZeroPad('0x00', 32)
  );
  const tierFrens = await Factory.deploy(
    'Thirsty Thirsty Season 1 - "Frens & Fams"',
    'TT',
    '',
    openSeaProxyRegistryAddress,
    100,
    ethers.utils.parseEther('0'),
    ethers.utils.hexZeroPad('0x00', 32)
  );

  await tierCellar.deployed();
  await tierTable.deployed();
  await tierTableGold.deployed();
  await tierFrens.deployed();

  console.log('"Cellar" deployed to:', tierCellar.address);
  console.log('"Table" deployed to:', tierTable.address);
  console.log('"Table Gold" deployed to:', tierTableGold.address);
  console.log('"Frens & Fam" deployed to:', tierFrens.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
