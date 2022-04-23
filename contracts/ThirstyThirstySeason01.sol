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

    string private _metadataBaseURI;

    /** @dev Cut gas cost by using counter instead of ERC721Enumerable's totalSupply. */
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    uint256 public maxSupply;
    uint256 public mintPriceInWei; // Top tier = .3ETH, Tier 2 = .08ETH, Goldlist = .05

    bytes32 public merkleRoot; // Fill variable before deployment, if used.

    /**
     * OpenSea proxy to remove listing fees.
     * https://etherscan.io/accounts/label/opensea
     * Rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
     * Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
     */
    address public proxyRegistryAddress;
    mapping(address => uint8) private mintsPerUser;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        address _proxyRegistryAddress,
        uint256 _maxSupply,
        uint256 _mintPriceInWei,
        bytes32 _merkleRoot
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        mintPriceInWei = _mintPriceInWei;
        merkleRoot = _merkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress;
        _metadataBaseURI = _metadataURI;

        _nextTokenId.increment();
    }

    function mint() public payable {
        uint256 mintIndex = _nextTokenId.current();
        require((mintIndex <= maxSupply), "Sold out");
        require((msg.value >= mintPriceInWei), "Not enough fund");
        // Max mint is 6, not stored in storage variable for performance reasons
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");

        mintsPerUser[msg.sender] += 1;
        _nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function mintGold(bytes32[] calldata _merkleProof) public payable {
        require((mintsPerUser[msg.sender] < 6), "No more mint for user");
        if (merkleRoot != 0) {
            require(mintsPerUser[msg.sender] == 0, "Address has already claimed");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not in goldlist");
        }
        uint256 mintIndex = _nextTokenId.current();
        require((mintIndex <= maxSupply), "Sold out");
        require((msg.value >= mintPriceInWei), "Not enough fund");

        mintsPerUser[msg.sender] += 1;
        _nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function nextTokenID() public view returns (uint256) {
        return _nextTokenId.current();
    }

    function numOfMints() public view returns (uint256) {
        return _nextTokenId.current() - 1;
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
        return _metadataBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
