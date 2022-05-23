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
     * @dev Cut gas cost by using counter instead of ERC721Enumerable's totalSupply.
     */
    Counters.Counter private nextTokenId;

    /**
     * @dev MAX TOKEN A USER CAN MINT: 6
     * Not stored in contract storage for performance reasons.
     */

    /**
     * @dev Base URI for metadata file.
     */
    string private metadataBaseURI;

    /**
     * @dev Merkle tree root used to check if a given address is in the goldlist.
     */
    bytes32 public merkleRoot;

    /**
     * @dev Must be true for regular mints to be allowed.
     * Goldlist mints can be done no matter what this value is.
     */
    bool public isMintStarted;

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
    mapping(address => uint64) private mintsPerUser;

    /**
     * @dev Map ID of minted token to its Tier ID.
     */
    mapping(uint256 => uint64) private tokenIdToTierId;

    /**
     * @dev TIER IDs | supply | price in wei | human-readable name
     * 1 | 270 | 0.4 | Cellar
     * 2 | 518 | 0.2 | Table
     * 3 | 100 | 0.1 | Table (goldlist)
     * 4 |  50 | 0   | Friends & Fam
     */
    struct Tier {
        uint64 id;
        uint64 minted;
        uint64 supply;
        uint256 priceInWei;
    }

    Tier private tierCellar;
    Tier private tierTable;
    Tier private tierTableGold;
    Tier private tierFriends;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        bool _isMintStarted,
        address _proxyRegistryAddress,
        Tier memory _tierCellar,
        Tier memory _tierTable,
        Tier memory _tierTableGold,
        Tier memory _tierFriends,
        bytes32 _merkleRoot
    ) ERC721(_name, _symbol) {
        isMintStarted = _isMintStarted;
        tierCellar = _tierCellar;
        tierTable = _tierTable;
        tierTableGold = _tierTableGold;
        tierFriends = _tierFriends;

        merkleRoot = _merkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress;
        metadataBaseURI = _metadataURI;

        nextTokenId.increment();
    }

    function mint(uint8 _tierId) public payable whenNotPaused {
        require(isMintStarted == true, "Not yet started");
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        uint256 mintIndex = nextTokenId.current();
        require(_tierId == tierCellar.id || _tierId == tierTable.id, "Unknown tier");

        Tier memory tier;
        if (_tierId == 1) {
            tier = tierCellar;
        } else {
            tier = tierTable;
        }
        require(tier.minted < tier.supply, "Sold out");
        require(msg.value >= tier.priceInWei, "Not enough fund");

        mintsPerUser[msg.sender] += 1;
        tier.minted += 1;
        tokenIdToTierId[mintIndex] = _tierId;
        nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function mintGold(bytes32[] calldata _merkleProof) public payable whenNotPaused {
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        require(merkleRoot != 0, "Merkle root not set");
        require(mintsPerUser[msg.sender] == 0, "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not in goldlist");
        require(tierTableGold.minted < tierTableGold.supply, "Sold out (goldlist)");
        require(msg.value >= tierTableGold.priceInWei, "Not enough fund");

        uint256 mintIndex = nextTokenId.current();
        mintsPerUser[msg.sender] += 1;
        tierTableGold.minted += 1;
        tokenIdToTierId[mintIndex] = tierTableGold.id;
        nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function airdrop(address _to) public onlyOwner whenNotPaused {
        require((mintsPerUser[_to] < 6), "No more mint for user");
        uint256 mintIndex = nextTokenId.current();
        require(tierFriends.minted < tierFriends.supply, "Sold out (airdrop)");

        mintsPerUser[msg.sender] += 1;
        tierFriends.minted += 1;
        tokenIdToTierId[mintIndex] = tierFriends.id;
        nextTokenId.increment();
        _safeMint(_to, mintIndex);
    }

    function withdraw(address _to) public onlyOwner {
        //
    }

    function nextTokenID() public view returns (uint256) {
        return nextTokenId.current();
    }

    function totalMinted() public view returns (uint256) {
        return nextTokenId.current() - 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        // Fetch tokenURI based on the tier ID.
        // Four metadata files exist -- one per tier.
        uint64 tierId = tokenIdToTierId[_tokenId];
        return string(abi.encodePacked(super.tokenURI(tierId), ".json"));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMintStarted(bool _started) public onlyOwner whenNotPaused {
        isMintStarted = _started;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner whenNotPaused {
        merkleRoot = _merkleRoot;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner whenNotPaused {
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
