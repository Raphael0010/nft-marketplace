// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Escrow is ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsInSell;

    address public digiMatAddress = 0x0000000000000000000000000000000000000000;
    address[] public redeemers;
     
    constructor() {
        digiMatAddress = msg.sender;
    }
    
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable owner;
        address[] oldOwner;
        address payable creator;
        uint256[] oldPriceSold;
        uint256 price;
        uint256 fee;
        bool inSell;
    }

    event MarketItemCreated (
        uint itemId,
        address nftContract,
        uint256 tokenId,
        address payable owner,
        address[] oldOwner,
        address payable creator,
        uint256[] oldPriceSold,
        uint256 price,
        uint256 fee,
        bool inSell
    );

    mapping(uint256 => MarketItem) private marketItem;
    

    // NFT CONTRACT = le contrat NFT de l'item ( peut etre différents selon le projet , APE/ETC/...)
    // tokenId = l'id du token gérnérer par le contrat NFT
    function depositMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        marketItem[itemId].itemId = itemId;
        marketItem[itemId].nftContract = nftContract;
        marketItem[itemId].tokenId = tokenId;
        marketItem[itemId].owner = payable(msg.sender);
        marketItem[itemId].price = price;
        marketItem[itemId].inSell = false;
        marketItem[itemId].fee = 0;

        IERC721(nftContract).transferFrom(msg.sender, digiMatAddress, tokenId);
    }
    
    function buyNFTFromEscrow(address nftContract,uint256 itemId) public payable nonReentrant {
        uint price = marketItem[itemId].price;
        uint tokenId = marketItem[itemId].tokenId;
        uint fee = marketItem[itemId].fee;
        address toPay = marketItem[itemId].owner;

        require(msg.value == price + fee, "Please submit the asking price in order to complete the purchase");
        // On vérifie que le NFT est bien en vente
        require(marketItem[itemId].inSell == true, "This NFT is not for sale");
        // On vérifie que le NFT à bien eu des frais de setup
        require(marketItem[itemId].fee != 0, "This NFT has not been setup");
        
        // on met l'ancien owner dans la liste des ancien proprio
        marketItem[itemId].oldOwner.push(toPay);
        // on garde a jours les prix des NFTs vendus
        marketItem[itemId].oldPriceSold.push(price);
        // Il paye les frais
        payable(digiMatAddress).transfer(fee);

        marketItem[itemId].owner = payable(msg.sender);
        marketItem[itemId].inSell = false;

        //Lancien propriétaire reçoit le prix
        payable(toPay).transfer(price);

        // L'acheteur reçoit le NFT
        IERC721(nftContract).transferFrom(digiMatAddress, msg.sender, tokenId);
    }

    function setFee(uint256 fee, uint256 itemId) public {
        require(fee > 0, "Fee must be greater than 0");
        require(digiMatAddress == msg.sender, "You cannot set the fee");

        marketItem[itemId].fee = fee;
    }

    function activateSell(uint256 itemId) public {
        require(marketItem[itemId].inSell == false);
        require(marketItem[itemId].owner == msg.sender);

        marketItem[itemId].inSell = true;
        _itemsInSell.increment();
    }

    function deactivateSell(uint256 itemId) public {
        require(marketItem[itemId].inSell == true);
        require(marketItem[itemId].owner == msg.sender);

        marketItem[itemId].inSell = false;
        _itemsInSell.decrement();
    }

    // Fonction pour lister tous les items en vente sur le market
    // On va simplement chercher tous les items avec le inSell = true
    function fetchMarketItemsInSell() public view returns (MarketItem[] memory) {
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](_itemsInSell.current());
        for(uint i = 0; i< _itemIds.current(); i++){
            if(marketItem[i + 1].inSell == true){
                uint currenId = marketItem[i + 1].itemId;
                MarketItem storage currentItem = marketItem[currenId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    //Fonction pour lister tous les items que je possède
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // Me permet de savoir combien je possède de NFT !
        for(uint i = 0; i < totalItemCount; i++){
            if(marketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i = 0; i < totalItemCount; i++){
            if(marketItem[i + 1].owner == msg.sender){
                uint currentId = marketItem[i + 1].itemId;
                MarketItem storage currentItem = marketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    //Fonction pour lister tous les items que j'ai créé
    function fetchMyNFTsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // Me permet de savoir combien de NFT j'ai créé !
        for(uint i = 0; i < totalItemCount; i++){
            if(marketItem[i + 1].creator == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i = 0; i < totalItemCount; i++){
            if(marketItem[i + 1].creator == msg.sender){
                uint currentId = marketItem[i + 1].itemId;
                MarketItem storage currentItem = marketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

}