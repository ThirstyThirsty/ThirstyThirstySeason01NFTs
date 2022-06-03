import { ethers } from 'hardhat';

import {
  PRICE_CELLAR,
  PRICE_TABLE,
  PRICE_TABLE_GOLD,
  TIER_CELLAR_ID,
  TIER_TABLE_ID,
  TIER_TABLE_GOLD_ID,
  TIER_FRENS_ID,
} from '../utils/constants'

export const tierCellar = {
  id: TIER_CELLAR_ID,
  supply: 270,
  priceInWei: PRICE_CELLAR
}
export const tierTable = {
  id: TIER_TABLE_ID,
  supply: 418,
  priceInWei: PRICE_TABLE
}
export const tierTableGold = {
  id: TIER_TABLE_GOLD_ID,
  supply: 100,
  priceInWei: PRICE_TABLE_GOLD
}
export const tierFrens = {
  id: TIER_FRENS_ID,
  supply: 50,
  priceInWei: ethers.BigNumber.from(0)
}
