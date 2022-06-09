import { generateMerkleTree, getMerkleRoot } from '../utils/goldlist'
const list = require('./goldlist.json')

const merkleTree = generateMerkleTree(list);
const envVar = list.join(',')

console.log()
console.info('----------------------------------------------------------------------------------------------------------------------------')
console.info('Merkle root generated:', getMerkleRoot(merkleTree), "\n")
console.info('Please update the address above in the smart contract using the `setMerkleRoot` methods.')
console.info("Contract address on Rinkeby: 0x68c0D7CdC7c5Bc028C66Ff933524F30C736fC8EC")
console.info("Contract address on Mainnet: 0x9a1a77CF312DD43D6Da93c5Ed5D2b4ef592e8962\n")
console.info('Add the following string of public keys to the GOLDLIST env variable of the minting web application:')
console.info(envVar)
console.info('----------------------------------------------------------------------------------------------------------------------------')
console.log()
