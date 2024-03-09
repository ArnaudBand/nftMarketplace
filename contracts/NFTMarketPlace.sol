// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Internal imports for NFT OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { Counters } from "./Counters.sol";

contract NFTMarketPlace is ERC721URIStorage {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  uint256 listingPrice = 0.0015 ether;

  address payable owner;

  struct MarketItem {
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
  }
  
  mapping (uint256 => MarketItem) private idMarketItem;

  event MarketItemCreated(
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  constructor() ERC721("NFT Metaverse Token", "NFTMP") {
    owner == payable(msg.sender);
  }


  function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
    listingPrice = _listingPrice;
  }

  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  // CREATE NFT TOKEN FUNCTION

  function createToken(string memory tokenURI, uint256 price) public payable returns(uint256) {
    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);

    crateMarketItem(newTokenId, price);

    return newTokenId;
  }

  // CREATE MARKET ITEM FUNCTION
  function crateMarketItem(uint256 tokenId, uint256 price) private {
    require(price > 0, "Price must be at least 1");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    idMarketItem[tokenId] = MarketItem(
      tokenId,
      payable(msg.sender),
      payable(address(this)),
      price,
      false
    );
  }
}