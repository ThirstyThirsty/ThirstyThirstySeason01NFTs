import { BigNumber, BigNumberish } from 'ethers'

export interface Tier {
  id: BigNumberish
  supply: BigNumberish
  priceInWei: BigNumber
}
