import {
  NAME,
  SYMBOL,
  METADATA_BASE_URI
} from '../utils/constants';

import {
  tierCellar,
  tierTable,
  tierTableGold,
  tierFrens,
} from './tiers';

const OS_PROXY_ADDR = process.env.OS_PROXY_ADDR_MAINNET;
const MERKLE_ROOT = process.env.MERKLE_ROOT;

module.exports = [
  NAME,
  SYMBOL,
  METADATA_BASE_URI,
  OS_PROXY_ADDR,
  tierCellar,
  tierTable,
  tierTableGold,
  tierFrens,
  MERKLE_ROOT
];
