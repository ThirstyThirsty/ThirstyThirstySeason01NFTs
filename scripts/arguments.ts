import {
  OS_PROXY_ADDR,
  MERKLE_ROOT,
  NAME,
  SYMBOL,
  METADATA_BASE_URI
} from '../utils/constants';

import {
  tierCellar,
  tierTable,
  tierTableGold,
  tierFrens,
} from './deploy';

module.exports = [
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
];
