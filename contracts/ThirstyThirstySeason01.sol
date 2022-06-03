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
    string public metadataBaseURI;

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

    enum TierID {
        CELLAR,
        TABLE,
        TABLE_GOLD,
        FRENS
    }

    /**
     * @dev Map Tier ID to the count of related NFTs minted.
     */
    mapping(TierID => uint256) private mintsPerTiers;

    /**
     * @dev Map ID of minted token to its Tier ID.
     */
    mapping(uint256 => TierID) private tokenIdToTierId;

    /**
     * @dev Count the current number of NFT minted by each user.
     */
    mapping(address => uint64) private mintsPerUser;

    /**
     * @dev TIER IDs   | SUPPLY | PRICE (ETH)
     *      CELLAR     | 270    | 0.4
     *      TABLE      | 518    | 0.2
     *      TABLE_GOLD | 100    | 0.1
     *      FRENS      |  50    | 0
     */
    struct Tier {
        TierID id;
        uint64 supply;
        uint256 priceInWei;
    }

    Tier private tierCellar;
    Tier private tierTable;
    Tier private tierTableGold;
    Tier private tierFrens;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        address _proxyRegistryAddress,
        Tier memory _tierCellar,
        Tier memory _tierTable,
        Tier memory _tierTableGold,
        Tier memory _tierFrens,
        bytes32 _merkleRoot
    ) ERC721(_name, _symbol) {
        tierCellar = _tierCellar;
        tierTable = _tierTable;
        tierTableGold = _tierTableGold;
        tierFrens = _tierFrens;
        merkleRoot = _merkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress;
        metadataBaseURI = _metadataURI;

        nextTokenId.increment();
    }

    function mintCellar() public payable whenNotPaused {
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        _mintCellar();
    }

    function mintTable() public payable whenNotPaused {
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        _mintTable();
    }

    function mintGold(bytes32[] calldata _merkleProof) public payable whenNotPaused {
        require(mintsPerUser[msg.sender] == 0, "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not in goldlist");
        require(mintsPerTiers[TierID.TABLE_GOLD] < tierTableGold.supply, "Sold out (goldlist)");
        require(msg.value >= tierTableGold.priceInWei, "Not enough fund");

        uint256 mintIndex = nextTokenId.current();

        mintsPerUser[msg.sender] += 1;
        mintsPerTiers[TierID.TABLE_GOLD] += 1;
        tokenIdToTierId[mintIndex] = TierID.TABLE_GOLD;
        nextTokenId.increment();

        _safeMint(msg.sender, mintIndex);
    }

    function airdrop(address _to) public onlyOwner whenNotPaused {
        require((mintsPerUser[_to] < 6), "No more mint for user");
        require(mintsPerTiers[TierID.FRENS] < tierFrens.supply, "Sold out (airdrop)");

        uint256 mintIndex = nextTokenId.current();

        mintsPerUser[msg.sender] += 1;
        mintsPerTiers[TierID.FRENS] += 1;
        tokenIdToTierId[mintIndex] = TierID.FRENS;
        nextTokenId.increment();

        _safeMint(_to, mintIndex);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    function nextTokenID() public view returns (uint256) {
        return nextTokenId.current();
    }

    function totalMinted() public view returns (uint256) {
        return nextTokenId.current() - 1;
    }

    function mintedPerTiers() public view returns (uint256[4] memory) {
        uint256[4] memory mints = [
            mintsPerTiers[TierID.CELLAR],
            mintsPerTiers[TierID.TABLE],
            mintsPerTiers[TierID.TABLE_GOLD],
            mintsPerTiers[TierID.FRENS]
        ];
        return mints;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        // Fetch tokenURI based on the tier ID.
        // Four metadata files exist -- one per tier.
        TierID tierId = tokenIdToTierId[_tokenId];
        uint256 uintTierId = uint256(tierId);
        string memory stringTierId = Strings.toString(uintTierId);
        return string(abi.encodePacked(metadataBaseURI, stringTierId, ".json"));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner whenNotPaused {
        merkleRoot = _merkleRoot;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner whenNotPaused {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory _uri) public onlyOwner whenNotPaused {
        metadataBaseURI = _uri;
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

    function _mintCellar() internal {
        require(mintsPerTiers[TierID.CELLAR] < tierCellar.supply, "Sold out");
        require(msg.value >= tierCellar.priceInWei, "Not enough fund");

        uint256 mintIndex = nextTokenId.current();

        mintsPerUser[msg.sender] += 1;
        mintsPerTiers[TierID.CELLAR] += 1;
        tokenIdToTierId[mintIndex] = TierID.CELLAR;
        nextTokenId.increment();

        _safeMint(msg.sender, mintIndex);
    }

    function _mintTable() internal {
        require(mintsPerTiers[TierID.TABLE] < tierTable.supply, "Sold out");
        require(msg.value >= tierTable.priceInWei, "Not enough fund");

        uint256 mintIndex = nextTokenId.current();

        mintsPerUser[msg.sender] += 1;
        mintsPerTiers[TierID.TABLE] += 1;
        tokenIdToTierId[mintIndex] = TierID.TABLE;
        nextTokenId.increment();

        _safeMint(msg.sender, mintIndex);
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
