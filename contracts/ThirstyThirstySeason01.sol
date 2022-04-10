// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract ThirstyThirstySeason01 is ERC721, Ownable, Pausable {

    using Strings for uint256;

    string private _metadataBaseURI;

    /** @dev Cut gas cost by using counter instead of ERC721Enumerable's totalSupply. */
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    uint256 public maxSupply;
    uint256 public mintPriceInWei; // Top tier = .3ETH, Tier 2 = .08ETH, Goldlist = .05

    bytes32 public merkleRoot; // Fill variable before deployment, if used.
    mapping(address => uint8) private _mintsPerUser;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        uint256 _maxSupply,
        uint256 _mintPriceInWei,
        bytes32 _merkleRoot
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        mintPriceInWei = _mintPriceInWei;
        merkleRoot = _merkleRoot;
        _metadataBaseURI = _metadataURI;

        _nextTokenId.increment();
    }

    function mint() public payable {
        uint256 mintIndex = _nextTokenId.current();
        // Avoid using >= and <= for performance reason.
        require((mintIndex < maxSupply) || (mintIndex == maxSupply), "Sold out");
        require((msg.value > mintPriceInWei) || (msg.value == mintPriceInWei), "Not enough fund");
        // Max mint is 6, not stored in storage variable for performance reasons
        require((_mintsPerUser[msg.sender] < 6), "No more mint for user");

        _mintsPerUser[msg.sender] += 1;
        _nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function mintGold(bytes32[] calldata _merkleProof) public payable {
        if (merkleRoot != 0) {
            require(_mintsPerUser[msg.sender] == 0, "Address has already claimed");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not in goldlist");
        }
        uint256 mintIndex = _nextTokenId.current();
        require((mintIndex < maxSupply) || (mintIndex == maxSupply), "Sold out");
        require((msg.value > mintPriceInWei) || (msg.value == mintPriceInWei), "Not enough fund");

        _mintsPerUser[msg.sender] += 1;
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
