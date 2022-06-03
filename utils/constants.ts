import { ethers } from 'hardhat'

export const OS_PROXY_ADDR = '0xf57b2c51ded3a29e6891aba85459d600256cf317' // Rinkeby

export const TIER_CELLAR_ID = 0
export const TIER_TABLE_ID = 1
export const TIER_TABLE_GOLD_ID = 2
export const TIER_FRENS_ID = 3

export const PRICE_CELLAR = ethers.utils.parseEther('0.4')
export const PRICE_TABLE = ethers.utils.parseEther('0.2')
export const PRICE_TABLE_GOLD = ethers.utils.parseEther('0.1')

export const MERKLE_ROOT = '0x8119db860a798f0291891a65160d30736a74c2ac673c31b934ceb202c5654ccd'

export const NAME = 'Thirsty Thirsty NFT'
export const SYMBOL = 'TT'

export const METADATA_BASE_URI = 'https://gateway.pinata.cloud/ipfs/QmbD8Dh1DrCautB8UBx7mVLYfcL8BtBAfkMpBJTGqn63nK'
