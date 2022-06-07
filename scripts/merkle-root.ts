import { generateMerkleTree, getMerkleRoot } from '../utils/goldlist'
const list = require('./goldlist.json')

const merkleTree = generateMerkleTree(list);
const envVar = list.join(',')

console.log()
console.info('----------------------------------------------------------------------------------------------------------------------------')
console.info('Merkle root generated:', getMerkleRoot(merkleTree), "\n")
console.info('Please update the address above in the "Table (Goldlist)" instance of the smart contract using the `setMerkleRoot` methods.')
console.info("Contract address on Rinkeby: 0x4413Ce6eed4e5C5a79D4a4547d3EB353F449dFc1")
console.info("Contract address on Mainnet: TBD\n")
console.info('Add the following string of public keys to the GOLDLIST env variable of the minting web application:')
console.info(envVar)
console.info('----------------------------------------------------------------------------------------------------------------------------')
console.log()
