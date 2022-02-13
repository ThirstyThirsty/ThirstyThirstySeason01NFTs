// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol";


contract ThirstyThirstySeason01 is ERC721, Ownable, Pausable {

    /**
     * @dev Cut gas cost by using counter instead of ERC721Enumerable's totalSupply.
     */
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    bool public isRevealed = false;
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;

    uint256 public maxSupply;
    uint256 public mintPriceInWei;

    string public defaultMetadataURI;

    bytes32 public merkleRoot; // Fill variable before deployment
    mapping(address => bool) private allowListClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPriceInWei,
        string memory _defaultMetadataURI
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        mintPriceInWei = _mintPriceInWei;
        defaultMetadataURI = _defaultMetadataURI;

        _nextTokenId.increment();
    }

    function presaleMint(bytes32[] calldata _merkleProof) public payable {
        require(isPresaleActive, "Presale not open yet.");

        require(!allowListClaimed[msg.sender], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not in allow-list.");

        uint256 mintIndex = _nextTokenId.current();
        require((mintIndex < maxSupply) || (mintIndex == maxSupply), "Sold out.");
        require((msg.value > mintPriceInWei) || (msg.value == mintPriceInWei), "Not enough fund.");

        allowListClaimed[msg.sender] = true;
        _nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function publicMint() public payable {
        require(!isPresaleActive, "Presale still active.");
        require(isPublicSaleActive, "Public sale not open yet.");

        uint256 mintIndex = _nextTokenId.current();
        require((mintIndex < maxSupply) || (mintIndex == maxSupply), "Sold out.");
        require((msg.value > mintPriceInWei) || (msg.value == mintPriceInWei), "Not enough fund.");

        _nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function activatePresale() public onlyOwner {
        require(!isPresaleActive, "Presale already active.");
        require(!isPublicSaleActive, "Public sale is active.");

        isPresaleActive = true;
    }

    function activatePublicSale() public onlyOwner {
        require(isPresaleActive, "Presale not activated prior.");
        require(!isPublicSaleActive, "Public sale already active.");

        isPresaleActive = false;
        isPublicSaleActive = true;
    }

    function tokensMinted() public view returns (uint256) {
        return _nextTokenId.current();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reveal() public onlyOwner {
        require(!isRevealed, "Already revealed.");
        isRevealed = true;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (!isRevealed) {
            return defaultMetadataURI;
        }

        return super.tokenURI(_tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
