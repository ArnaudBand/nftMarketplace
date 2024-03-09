// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Internal imports for NFT OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { Counters } from "./Counters.sol";

contract NFTMarketPlace is ERC721URIStorage {

// Uses the Counters library for its counters
  using Counters for Counters.Counter;          

  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  uint256 listingPrice = 0.0015 ether;

  address payable owner;
// Structure to represent a market item
  struct MarketItem {                          
    uint256 tokenId;                            
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
  }
  // Mapping to store market items by token ID
  mapping (uint256 => MarketItem) private idMarketItem;

  // Event emitted when a market item is created
  event MarketItemCreated(
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );
  // Restricts function access to the owner
  modifier onlyOwner() {                      
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }
  // Constructor that initializes the contract
  constructor() ERC721("NFT Metaverse Token", "NFTMP") {
    owner = payable(msg.sender);                      
  }
  // Function to update the listing price
  function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
    listingPrice = _listingPrice;
  }
 // Function to retrieve the current listing price
  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  // Create a new NFT token and list it for sale

  function createToken(string memory tokenURI, uint256 price) public payable returns(uint256) {
    _tokenIds.increment();

    uint256 newTokenId = _tokenIds.current();
   // Mints the new token
    _mint(msg.sender, newTokenId);                  
    _setTokenURI(newTokenId, tokenURI);
  // Creates a corresponding market item
    crateMarketItem(newTokenId, price);
    // Returns the token ID of the created token
    return newTokenId;
  }

  // Create a market item for a token
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

    _transfer(msg.sender, address(this), tokenId);

    emit MarketItemCreated(
      tokenId,
      msg.sender,
      address(this),
      price,
      false
    );
  }

  // Resell the purchased token at your owner price
  function resellToken(uint256 tokenId, uint256 price) public payable {
    require(idMarketItem[tokenId].owner == msg.sender, "You are not the owner of this token");
    require(msg.value == listingPrice, "Price must be equal to listing price");
    // Creates a corresponding market item
    idMarketItem[tokenId].price = price;
    idMarketItem[tokenId].sold = false;
    idMarketItem[tokenId].seller = payable(msg.sender);
    idMarketItem[tokenId].owner = payable(address(this));

    _itemsSold.decrement();

    _transfer(msg.sender, address(this), tokenId);
  }

  function createMaketSale(uint256 tokenId) public payable {
    uint256 price = idMarketItem[tokenId].price;
    require(
      msg.value == price,
      "Please submit the asking price in order to complete the purchase"
    );

    idMarketItem[tokenId].owner = payable(msg.sender);
    idMarketItem[tokenId].sold = true;
    idMarketItem[tokenId].owner = payable(address(0));

    _itemsSold.increment();

    _transfer(address(this), msg.sender, tokenId);

    payable(owner).transfer(listingPrice);
    payable(idMarketItem[tokenId].seller).transfer(msg.value);
  }
// Get unsold NFT tokens
  function fetchMarketItem() public view returns(MarketItem[] memory) {
    uint256 itemCount = _tokenIds.current();
    uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint256 currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);

    for (uint i = 0; i < itemCount; i++) {
      if (idMarketItem[i + 1].owner == address(this)) {
        uint256 currentId = idMarketItem[i + 1].tokenId;
        MarketItem storage currentItem = idMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}
