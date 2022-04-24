import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

export const generateMerkleTree = (whitelistAddresses: string[]) => {
  const leafNodes = whitelistAddresses.map(addr => keccak256(addr))
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
  return merkleTree
}

export const getMerkleRoot = (merkleTree: MerkleTree): string => {
  return '0x' + merkleTree.getRoot().toString('hex')
}
