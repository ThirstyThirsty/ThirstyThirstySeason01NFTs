import { generateMerkleTree, getMerkleRoot } from '../utils/goldlist'
const list = require('./goldlist.json')

const merkleTree = generateMerkleTree(list);
console.info('Merkle root generated:', getMerkleRoot(merkleTree))
