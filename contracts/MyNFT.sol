// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./base/ERC721EnumerableUpgradeable.sol";
import "./base/ERC721Upgradeable.sol";
import "./base/EIP712SigMint.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyNFT is ERC721EnumerableUpgradeable, EIP712SigMint, OwnableUpgradeable {
    string public baseURI;
    uint256 public nextTokenId;
    mapping(uint256 => uint256) public itemIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToItemId;

    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        nextTokenId = 1;
    }

    function addSigner(address _signer) external onlyOwner {
        _addSigner(_signer);
    }

    function removeSigner(address _signer) external onlyOwner {
        _removeSigner(_signer);
    }

    function mint(
        address user,
        uint256 itemId,
        uint256 validUntil,
        bytes calldata signature
    ) public {
        _checkEIP712Signature(user, itemId, validUntil, signature);
        require(itemId > 0, "Invalid item id");
        require(itemIdToTokenId[itemId] == 0, "Item already minted");
        _safeMint(user, nextTokenId);
        itemIdToTokenId[itemId] = nextTokenId;
        tokenIdToItemId[nextTokenId] = itemId;
        nextTokenId++;
    }

    function batchMint(
        address user,
        uint256[] memory itemIds,
        uint256 validUntil,
        bytes[] calldata signatures
    ) external {
        require(itemIds.length == signatures.length, "Invalid input");
        for (uint256 i = 0; i < itemIds.length; i++) {
            mint(user, itemIds[i], validUntil, signatures[i]);
        }
    }

    function batchItemIdToTokenId(uint256[] calldata itemIds)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](itemIds.length);
        for (uint256 i = 0; i < itemIds.length; i++) {
            tokenIds[i] = itemIdToTokenId[itemIds[i]];
        }
    }

    function batchTokenIdToItemId(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory itemIds)
    {
        itemIds = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            itemIds[i] = tokenIdToItemId[tokenIds[i]];
        }
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        return bytes(baseURI).length > 0 ? string.concat(baseURI, Strings.toString(tokenId)) : "";
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenOfOwner(address user, uint256 start_index, uint256 end_index)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        uint256 balance = balanceOf[user];

        if(end_index >= balance) {
            if(balance == 0)
            {
                end_index = 0;
            }
            else
            {
                end_index = balance - 1;
            }
        }
        if(start_index > end_index) {
            return new uint256[](0);
        }
        tokenIds = new uint256[](end_index - start_index + 1);
        for (uint256 i = start_index; i <= end_index; i++) {
            tokenIds[i - start_index] = tokenOfOwnerByIndex(user, i);
        }
    }
}
