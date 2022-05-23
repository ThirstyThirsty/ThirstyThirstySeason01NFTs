import { BigNumber, BigNumberish } from 'ethers'

export interface Tier {
  id: BigNumberish
  minted: BigNumberish
  supply: BigNumberish
  priceInWei: BigNumber
}
