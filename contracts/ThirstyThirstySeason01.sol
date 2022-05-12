// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OwnableDelegateProxy { }

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ThirstyThirstySeason01 is ERC721, Ownable, Pausable {

    using Strings for uint256;
    using Counters for Counters.Counter;

    /**
     * @dev TIER IDs
     * 1 => Cellar
     * 2 => Table
     * 3 => Table (goldlist)
     *
     * MAX TOKEN A USER CAN MINT: 6
     * Not stored in contract storage for performance reasons.
     */

    /**
     * @dev Base URI for metadata file.
     */
    string private metadataBaseURI;

    /**
     * @dev Cut gas cost by using counter instead of ERC721Enumerable's totalSupply.
     */
    Counters.Counter private nextTokenId;

    /**
     * @dev Merkle tree root used to check if a given address is in the goldlist.
     */
    bytes32 public merkleRoot;

    /**
     * @dev OpenSea proxy to remove listing fees on their site.
     * https://etherscan.io/accounts/label/opensea
     * Rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
     * Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
     */
    address public proxyRegistryAddress;

    /**
     * @dev Count the current number of NFT minted by each user.
     */
    mapping(address => uint8) private mintsPerUser;

    /**
     * @dev Max NFT supply for each tier.
     * A mapping of tier ID
     * Tier 1 (Cellar): ...
     * Tier 2 (Table): ...
     * Tier 3 (Table, goldlist): ...
     */
    mapping(uint8 => uint256) private maxSupplyPerTier;

    /**
     * @dev Count current number of mints for each tiers.
     */
    mapping(uint8 => uint256) private mintedPerTier;

    /**
     * @dev Mint price for each tier.
     * Tier 1 (Cellar): ...
     * Tier 2 (Table): ...
     * Tier 3 (Table, goldlist): ...
     */
    mapping(uint8 => uint256) private pricePerTier;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        address _proxyRegistryAddress,
        uint256 _maxSupplyPerTier1,
        uint256 _maxSupplyPerTier2,
        uint256 _maxSupplyPerTier3,
        uint256 _pricePerTier1,
        uint256 _pricePerTier2,
        uint256 _pricePerTier3,
        bytes32 _merkleRoot
    ) ERC721(_name, _symbol) {
        mintedPerTier[1] = 0;
        mintedPerTier[2] = 0;
        mintedPerTier[3] = 0;
        maxSupplyPerTier[1] = _maxSupplyPerTier1;
        maxSupplyPerTier[2] = _maxSupplyPerTier2;
        maxSupplyPerTier[3] = _maxSupplyPerTier3;
        pricePerTier[1] = _pricePerTier1;
        pricePerTier[2] = _pricePerTier2;
        pricePerTier[3] = _pricePerTier3;
        merkleRoot = _merkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress;
        metadataBaseURI = _metadataURI;

        nextTokenId.increment();
    }

    function mint(uint8 _tier) public payable {
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        uint256 mintIndex = nextTokenId.current();
        require(_tier == 1 || _tier == 2, "Unknown tier");
        require(mintedPerTier[_tier] < maxSupplyPerTier[_tier], "Sold out");
        require(msg.value >= pricePerTier[_tier], "Not enough fund");

        mintsPerUser[msg.sender] += 1;
        mintedPerTier[_tier] += 1;
        nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function mintGold(bytes32[] calldata _merkleProof) public payable {
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        require(merkleRoot != 0, "Merkle root not set");
        require(mintsPerUser[msg.sender] == 0, "Address has already claimed from goldlist");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not in goldlist");
        uint8 tier = 3;
        uint256 mintIndex = nextTokenId.current();
        require(mintedPerTier[tier] < maxSupplyPerTier[tier], "Sold out (goldlist)");
        require(msg.value >= pricePerTier[tier], "Not enough fund");

        mintsPerUser[msg.sender] += 1;
        mintedPerTier[tier] += 1;
        nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function airdrop(address _to) public onlyOwner {
        require((mintsPerUser[_to] < 6), "No more mint for user");
        uint8 tier = 2;
        uint256 mintIndex = nextTokenId.current();
        require(mintedPerTier[tier] < maxSupplyPerTier[tier], "Sold out");

        mintsPerUser[_to] += 1;
        mintedPerTier[tier] += 1;
        nextTokenId.increment();
        _safeMint(_to, mintIndex);
    }

    function nextTokenID() public view returns (uint256) {
        return nextTokenId.current();
    }

    function numOfMints() public view returns (uint256) {
        return nextTokenId.current() - 1;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return super.tokenURI(_tokenId);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract gas-free listing.
        if (proxyRegistryAddress != address(0)) {
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
