import { expect, use } from 'chai'
import { ethers } from 'hardhat'
import { Contract, BigNumber, BigNumberish } from 'ethers'
import { generateMerkleTree, getMerkleRoot } from '../utils/goldlist'
import keccak256 from 'keccak256'
import asPromised from 'chai-as-promised'
import {
  PRICE_CELLAR,
  PRICE_TABLE,
  PRICE_TABLE_GOLD,
  TIER_CELLAR_ID,
  TIER_TABLE_ID,
  TIER_TABLE_GOLD_ID,
  TIER_FRENS_ID
} from '../utils/constants'
import { ThirstyThirstySeason01 } from '../typechain-types/contracts/ThirstyThirstySeason01.sol/ThirstyThirstySeason01'

const OS_PROXY_ADDR = process.env.OS_PROXY_ADDR_RINKEBY ? process.env.OS_PROXY_ADDR_RINKEBY : '0x0';

use(asPromised)

const tierCellar = { id: TIER_CELLAR_ID, supply: 270, priceInWei: PRICE_CELLAR }
const tierTable = { id: TIER_TABLE_ID, supply: 518, priceInWei: PRICE_TABLE }
const tierTableGold = { id: TIER_TABLE_GOLD_ID, supply: 100, priceInWei: PRICE_TABLE_GOLD }
const tierFriends = { id: TIER_FRENS_ID, supply: 50, priceInWei: BigNumber.from(0) }

const createAndDeploy = async (
  name: string = 'Thirsty Thirsty',
  symbol: string = 'TT',
  baseURI: string = 'https://tt.dev/',
  merkleRoot: BigNumberish = ethers.utils.hexZeroPad('0x00', 32),
  tier1: ThirstyThirstySeason01.TierStruct = tierCellar,
  tier2: ThirstyThirstySeason01.TierStruct = tierTable,
  tier3: ThirstyThirstySeason01.TierStruct = tierTableGold,
  tier4: ThirstyThirstySeason01.TierStruct = tierFriends
): Promise<Contract> => {
  const Factory = await ethers.getContractFactory('ThirstyThirstySeason01')
  const contract = await Factory.deploy(
    name,
    symbol,
    baseURI,
    OS_PROXY_ADDR,
    tier1,
    tier2,
    tier3,
    tier4,
    merkleRoot
  )
  await contract.deployed()
  return contract
}

describe('ThirstyThirstySeason01', () => {
  let contract: Contract
  const baseURI = 'https://tt.dev/'

  beforeEach(async () => {
    contract = await createAndDeploy()
  })

  describe('deployment', () => {
    it('should be deployable', async () => {
      expect(contract).to.exist
    })

    it('should increment token ID counter to 1 upon deployment', async () => {
      await expect(contract.nextTokenID()).to.eventually.equal('1')
    })
  })

  describe('getters', () => {
    it('should return the current token ID with #nextTokenID', async () => {
      await expect(contract.nextTokenID()).to.eventually.equal('1')
    })

    it('should return the number of minted items with #totalMinted', async () => {
      await expect(contract.totalMinted()).to.eventually.equal('0')
      await contract.mintCellar({ value: PRICE_CELLAR })
      await expect(contract.totalMinted()).to.eventually.equal('1')
    })

    it("should fail if trying to call #tokenURI on non-existent token", async () => {
      await expect(contract.tokenURI('1'))
        .to.be.eventually.rejectedWith('URI query for nonexistent token')
    })

    it("should return a token's full URI, matching the token's tier ID, with #tokenURI", async () => {
      await contract.mintCellar({ value: PRICE_CELLAR })
      await contract.mintCellar({ value: PRICE_CELLAR })
      await contract.mintTable({ value: PRICE_TABLE })
      await expect(contract.tokenURI('1')).to.eventually.equal(`${baseURI}${TIER_CELLAR_ID}.json`)
      await expect(contract.tokenURI('2')).to.eventually.equal(`${baseURI}${TIER_CELLAR_ID}.json`)
      await expect(contract.tokenURI('3')).to.eventually.equal(`${baseURI}${TIER_TABLE_ID}.json`)
    })

    it('should return an array with all mints per tiers, ordered by their IDs, with #mintedPerTiers', async () => {
      await contract.mintCellar({ value: PRICE_CELLAR })
      await contract.mintCellar({ value: PRICE_CELLAR })
      await contract.mintCellar({ value: PRICE_CELLAR })
      await contract.mintCellar({ value: PRICE_CELLAR })
      await contract.mintTable({ value: PRICE_TABLE })
      await contract.mintTable({ value: PRICE_TABLE })

      const mintedPerTiers = await contract.mintedPerTiers()

      expect(mintedPerTiers[0]).to.equal(BigNumber.from(4))
      expect(mintedPerTiers[1]).to.equal(BigNumber.from(2))
      expect(mintedPerTiers[2]).to.equal(BigNumber.from(0))
      expect(mintedPerTiers[3]).to.equal(BigNumber.from(0))
    })
  })

  describe('#setMerkleRoot', () => {
    it('should update Merkle root value using #setMerkleRoot', async () => {
      let value = await contract.merkleRoot()
      expect(+value).to.equal(0)

      value = '0x81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000'
      await contract.setMerkleRoot(value)
      await expect(contract.merkleRoot()).to.eventually.equal(value)
    })

    it('prevents non-owner to #setMerkleRoot', async () => {
      const notOwner = (await ethers.getSigners())[1]
      await expect(contract.connect(notOwner).setMerkleRoot('0x81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000'))
        .to.be.rejectedWith('Ownable: caller is not the owner')
    })

    it('should fail if called when contract is paused', async () => {
      await contract.pause()
      await expect(contract.setMerkleRoot(ethers.utils.hexZeroPad('0x00', 32)))
        .to.eventually.be.rejectedWith('Pausable: paused')
    })
  })

  describe('#setBaseURI', () => {
    beforeEach(async () => {
      contract = await createAndDeploy(
        'Thirsty Thirsty',
        'TT',
        ''
      )
    })

    it('should update `metadataBaseURI` value using #setBaseURI', async () => {
      await expect(contract.metadataBaseURI()).to.eventually.equal('')
      const newVal = 'foo'
      await contract.setBaseURI(newVal)
      await expect(contract.metadataBaseURI()).to.eventually.equal(newVal)
    })

    it('prevents non-owner to #setMintStarted', async () => {
      const notOwner = (await ethers.getSigners())[1]
      await expect(contract.connect(notOwner).setBaseURI('foo'))
        .to.be.rejectedWith('Ownable: caller is not the owner')
    })

    it('should fail if called when contract is paused', async () => {
      await contract.pause()
      await expect(contract.setBaseURI('foo'))
        .to.be.rejectedWith('Pausable: paused')
    })
  })

  describe('#pause / #unpause', () => {
    it('should pause and unpause contract when owner asks for it', async () => {
      await expect(contract.paused()).to.eventually.equal(false)
      await contract.pause()
      await expect(contract.paused()).to.eventually.equal(true)
      await contract.unpause()
      await expect(contract.paused()).to.eventually.equal(false)
    })

    it('prevents non-owner to use pause functionality', async () => {
      const notOwner = (await ethers.getSigners())[1]
      await expect(contract.connect(notOwner).pause())
        .to.be.eventually.rejectedWith('Ownable: caller is not the owner')
      await expect(contract.connect(notOwner).unpause())
        .to.be.eventually.rejectedWith('Ownable: caller is not the owner')
    })
  })

  describe('#setProxyRegistryAddress', () => {
    it('prevents non-owner to use #setProxyRegistryAddress', async () => {
      const notOwner = (await ethers.getSigners())[1]
      await expect(contract.connect(notOwner).setProxyRegistryAddress(OS_PROXY_ADDR))
        .to.be.eventually.rejectedWith('Ownable: caller is not the owner')
    })

    it('updates proxyRegistryAddress with #setProxyRegistryAddress', async () => {
      const addr = (await contract.proxyRegistryAddress()).toLowerCase()
      const newAddr = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'
      expect(addr).to.equal(OS_PROXY_ADDR.toLowerCase())
      await expect(contract.setProxyRegistryAddress(newAddr)).to.be.eventually.fulfilled
      const updatedAddr = (await contract.proxyRegistryAddress()).toLowerCase()
      expect(updatedAddr).to.equal(newAddr)
    })

    it('should fail if called when contract is paused', async () => {
      await contract.pause()
      await expect(contract.setProxyRegistryAddress(OS_PROXY_ADDR))
        .to.be.rejectedWith('Pausable: paused')
    })
  })

  describe('#mintCellar', () => {
    it('should fail minting if not enough fund sent', async () => {
      await expect(contract.mintCellar({ value: ethers.utils.parseEther('0.1') }))
        .to.be.eventually.rejectedWith('Not enough fund')
    })

    it('should fail minting if address all available tokens have been minted', async () => {
      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI,
        ethers.utils.hexZeroPad('0x00', 32),
        { ...tierCellar, supply: 0 }
      )

      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.rejectedWith('Sold out')
    })

    it('should fail if user attempts to mint more than 6 tokens', async () => {
      contract = await createAndDeploy()

      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.rejectedWith('No more mint for user')
    })

    it('should fail if called when contract is paused', async () => {
      await contract.pause()
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.rejectedWith('Pausable: paused')
    })

    it('should mint a new token and increment next token ID', async () => {
      await expect(contract.mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.totalMinted()).to.eventually.equal('1')
      await expect(contract.nextTokenID()).to.eventually.equal('2')
    })
  })

  describe('#mintTable', () => {
    it('should fail minting if not enough fund sent', async () => {
      await expect(contract.mintTable({ value: ethers.utils.parseEther('0.1') }))
        .to.be.eventually.rejectedWith('Not enough fund')
    })

    it('should fail minting if address all available tokens have been minted', async () => {
      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI,
        ethers.utils.hexZeroPad('0x00', 32),
        tierCellar,
        { ...tierTable, supply: 0 }
      )

      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.rejectedWith('Sold out')
    })

    it('should fail if user attempts to mint more than 6 tokens', async () => {
      contract = await createAndDeploy()

      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.rejectedWith('No more mint for user')
    })

    it('should fail if called when contract is paused', async () => {
      await contract.pause()
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.rejectedWith('Pausable: paused')
    })

    it('should mint a new token and increment next token ID', async () => {
      await expect(contract.mintTable({ value: PRICE_TABLE }))
        .to.be.eventually.fulfilled
      await expect(contract.totalMinted()).to.eventually.equal('1')
      await expect(contract.nextTokenID()).to.eventually.equal('2')
    })
  })

  describe('#mintGold', () => {
    it('should mint from goldlist only if signer is in goldlist, then increment next token ID', async () => {
      const users = await ethers.getSigners()
      const whitelistAddresses = [
        users[1].address,
        users[2].address,
        users[5].address
      ]
      const merkleTree = generateMerkleTree(whitelistAddresses)
      const merkleRoot = getMerkleRoot(merkleTree)

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI, merkleRoot
      )

      await expect(
        contract
          .connect(users[1])
          .mintGold(
            merkleTree.getHexProof(keccak256(users[1].address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.fulfilled

      await expect(contract.totalMinted()).to.eventually.equal('1')
      await expect(contract.nextTokenID()).to.eventually.equal('2')

      await expect(
        contract
          .connect(users[2])
          .mintGold(
            merkleTree.getHexProof(keccak256(users[2].address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.fulfilled

      await expect(
        contract
          .connect(users[5])
          .mintGold(
            merkleTree.getHexProof(keccak256(users[5].address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.fulfilled

      await expect(
        contract
          .connect(users[4])
          .mintGold(
            merkleTree.getHexProof(keccak256(users[4].address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.rejectedWith('Address not in goldlist')
    })

    it('should fail if called when contract is paused', async () => {
      const users = await ethers.getSigners()
      const whitelistAddresses = [
        users[1].address,
        users[2].address,
        users[5].address
      ]
      const merkleTree = generateMerkleTree(whitelistAddresses)
      const merkleRoot = getMerkleRoot(merkleTree)

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI, merkleRoot
      )
      await contract.pause()

      await expect(
        contract
          .connect(users[1])
          .mintGold(
            merkleTree.getHexProof(keccak256(users[1].address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.rejectedWith('Pausable: paused')
    })

    it('should fail if user attempts to mint more than 6 tokens', async () => {
      const users = await ethers.getSigners()
      const whitelistAddresses = [
        users[1].address,
        users[2].address,
        users[5].address
      ]
      const merkleTree = generateMerkleTree(whitelistAddresses)
      const merkleRoot = getMerkleRoot(merkleTree)

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI, merkleRoot
      )

      await expect(
        contract
          .connect(users[5])
          .mintCellar({ value: PRICE_CELLAR })
        ).to.be.eventually.fulfilled

      await expect(
        contract
          .connect(users[5])
          .mintGold(
            merkleTree.getHexProof(keccak256(users[5].address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.rejectedWith('Address has already claimed')
    })

    it('should fail minting if address has already minted', async () => {
      const user = (await ethers.getSigners())[0]
      const merkleTree = generateMerkleTree([user.address])
      const merkleRoot = getMerkleRoot(merkleTree)

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI, merkleRoot
      )

      await expect(
        contract
          .mintGold(
            merkleTree.getHexProof(keccak256(user.address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.fulfilled

      await expect(
        contract
          .mintGold(
            merkleTree.getHexProof(keccak256(user.address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.rejectedWith('Address has already claimed')
    })

    it('should fail minting if address all available tokens have been minted', async () => {
      const user = (await ethers.getSigners())[0]
      const merkleTree = generateMerkleTree([user.address])
      const merkleRoot = getMerkleRoot(merkleTree)

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI,
        merkleRoot, tierCellar, tierTable,
        { ...tierTableGold, supply: 0 }
      )

      await expect(
        contract
          .mintGold(
            merkleTree.getHexProof(keccak256(user.address)),
            { value: PRICE_TABLE_GOLD }
          )
      ).to.be.eventually.rejectedWith('Sold out')
    })

    it('should fail minting if not enough fund sent', async () => {
      const user = (await ethers.getSigners())[0]
      const merkleTree = generateMerkleTree([user.address])
      const merkleRoot = getMerkleRoot(merkleTree)

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI, merkleRoot
      )

      await expect(
          contract
            .mintGold(
              merkleTree.getHexProof(keccak256(user.address)),
              { value: ethers.utils.parseEther('0.01') }
            )
        ).to.be.eventually.rejectedWith('Not enough fund')
    })
  })

  describe('#airdrop', () => {
    beforeEach(async () => {
      contract = await createAndDeploy()
    })

    it('prevents non-owner to use #airdrop', async () => {
      const notOwner = (await ethers.getSigners())[1]
      await expect(contract.connect(notOwner).airdrop('0x70997970c51812dc3a010c7d01b50e0d17dc79c8'))
        .to.be.rejectedWith('Ownable: caller is not the owner')
    })

    it('should revert if recipient wallet already owns 6 tokens', async () => {
      const recipient = (await ethers.getSigners())[1]
      await expect(contract.connect(recipient).mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.connect(recipient).mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.connect(recipient).mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.connect(recipient).mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.connect(recipient).mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled
      await expect(contract.connect(recipient).mintCellar({ value: PRICE_CELLAR }))
        .to.be.eventually.fulfilled

      await expect(contract.airdrop(recipient.address))
        .to.be.eventually.rejectedWith('No more mint for user')
    })

    it('should fail minting if address all available tokens have been minted', async () => {
      const recipient = (await ethers.getSigners())[1]

      contract = await createAndDeploy(
        'ThirstyThirsty', 'TT', baseURI,
        ethers.utils.hexZeroPad('0x00', 32),
        tierCellar, tierTable, tierTableGold,
        { ...tierFriends, supply: 0 }
      )

      await expect(contract.airdrop(recipient.address))
        .to.be.eventually.rejectedWith('Sold out')
    })

    it('should fail if called when contract is paused', async () => {
      await contract.pause()

      const recipient = (await ethers.getSigners())[1]
      await expect(contract.airdrop(recipient.address))
        .to.be.rejectedWith('Pausable: paused')
    })

    it('should mint a token to recipient wallet passed as argument', async () => {
      const recipient = (await ethers.getSigners())[1]
      await expect(contract.balanceOf(recipient.address)).to.be.eventually.equal('0')

      await expect(contract.airdrop(recipient.address))
      await expect(contract.balanceOf(recipient.address)).to.be.eventually.equal('1')
    })
  })

  describe('#transferOwnership', () => {
    it('should prevent non-owner to use #transferOwnership', async () => {
      const notOwner = (await ethers.getSigners())[1]
      const otherUser = (await ethers.getSigners())[2]
      await expect(contract.connect(notOwner).transferOwnership(otherUser.address))
        .to.be.eventually.rejectedWith('Ownable: caller is not the owner');
    })

    it('should transfer contract ownership to address passed as argument', async () => {
      const owner = (await ethers.getSigners())[0]
      const otherUser = (await ethers.getSigners())[2]
      await expect(contract.owner()).to.eventually.equal(owner.address)

      await expect(contract.transferOwnership(otherUser.address))
        .to.eventually.be.fulfilled

      await expect(contract.owner()).to.eventually.equal(otherUser.address)
    })
  })

  describe('#withdraw', () => {
    it('should prevent non-owner to use #withdraw', async () => {
      const notOwner = (await ethers.getSigners())[1]
      await expect(contract.connect(notOwner).withdraw())
        .to.be.eventually.rejectedWith('Ownable: caller is not the owner');
    })

    it('should transfer all remaining funds in the contract to the message sender (owner)', async () => {
      contract = await createAndDeploy()

      const owner = (await ethers.getSigners())[0]
      const minter = (await ethers.getSigners())[1]
      const origContractBalance = await ethers.provider.getBalance(contract.address)
      const origOwnerBalance = await ethers.provider.getBalance(owner.address)
      expect(origContractBalance).to.equal('0')

      const paid = ethers.utils.parseEther('5000')

      await contract.connect(minter).mintCellar({ value: paid })
      const newContractBalance = await ethers.provider.getBalance(contract.address)
      expect(newContractBalance).to.equal(paid)

      await contract.withdraw()
      const finalContractBalance = await ethers.provider.getBalance(contract.address)
      const newOwnerBalance = await ethers.provider.getBalance(owner.address)
      expect(finalContractBalance).to.equal('0')

      // New owner balance is somewhat superior to origBalance (~9999)
      // plus withdrawn funds (~5000) minus 1 ether to largely cover gas fees.
      expect(+ethers.utils.formatEther(newOwnerBalance.toString()))
        .to.be.greaterThanOrEqual(
          +ethers.utils.formatEther(origOwnerBalance.toString()) + 5000 - 1
        )
    })
  })
})
