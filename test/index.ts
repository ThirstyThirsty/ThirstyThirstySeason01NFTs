import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Contract, BigNumber } from 'ethers'
// import asPromised from 'chai-as-promised'

const createAndDeploy = async (
  name: string,
  symbol: string,
  baseURI: string,
  supply: number,
  price: BigNumber
): Promise<Contract> => {
  const Factory = await ethers.getContractFactory('ThirstyThirstySeason01')
  const contract = await Factory.deploy(
    name,
    symbol,
    baseURI,
    supply,
    price
  )
  await contract.deployed()
  return contract
}

describe('ThirstyThirstySeason01', function () {
  it('should be deployable with the proper arguments', async () => {
    const contract = await createAndDeploy(
      'ThirstyThirsty',
      'TT',
      'https://tt.dev',
      10,
      BigNumber.from('300000000000000000') // 0.3
    )
    expect(contract).to.exist
  })
});
