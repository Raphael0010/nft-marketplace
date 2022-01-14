// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// TODO: Possibilité de crée une commision pour le creator a chaque vente 
contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsInSell;

    address payable owner;
    uint256 listingPrice = 0.1 ether;
    uint256 commisionForCreatorPrice = 0.0001 ether;

    constructor(){
        owner = payable(msg.sender);
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
        bool inSell;
    }

    mapping (uint256 => MarketItem) idToMarketItem;
    
    event MarketItemCreated(
        uint256 indexed itemId, 
        address indexed nftContract, 
        uint256 indexed tokenId, 
        address owner, 
        address[] oldOwner,
        address creator, 
        uint256[] oldPriceSold,
        uint256 price,
        bool inSell
    );

    // Fonction pour retourner le prix minimum du listing
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Fonction pour créer et liste sur le marché un NFT
    // @param nftContract: Adresse du contrat NFT
    // @param tokenId: Id du token NFT
    // @param price: Prix de vente
    // Il faut que le prix du NFT soit supérieur au prix minimum du listing
    // Il faut que le montant envoyé soit supérieur au prix du listing
    function createAndListNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price >= listingPrice, "Price must be equal or greater than the listing price");
        require(msg.value >= listingPrice, "Price must be equal or greater than the listing price");

        _itemIds.increment();
        _itemsInSell.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId].itemId = itemId;
        idToMarketItem[itemId].nftContract = nftContract;
        idToMarketItem[itemId].tokenId = tokenId;
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].oldOwner.push(msg.sender);
        idToMarketItem[itemId].creator = payable(msg.sender);
        idToMarketItem[itemId].oldPriceSold.push(0);
        idToMarketItem[itemId].price = price;
        idToMarketItem[itemId].inSell = true;

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        // le creator/owner du NFT paye le prix de listing 
        payable(owner).transfer(listingPrice);

    }

    // Le propriétaire retire de la vente son NFT
    // @param itemId: Id de l'item
    function removeNFTFromMarket(
        uint256 itemId
    ) public payable nonReentrant {
        _itemsInSell.decrement();
        // On vérifie que celui qui appel le smart contract avec l'id du NFT le possède bien
        require(idToMarketItem[itemId].owner == msg.sender, "You are not the owner of this NFT");
        idToMarketItem[itemId].inSell = false;
    }

    // Le propriétaire met sur le market son NFT
    // @param itemId: Id de l'item
    function addNFTToMarket(
        uint256 itemId
    ) public payable nonReentrant {
        _itemsInSell.increment();
        // On vérifie que celui qui appel le smart contract avec l'id du NFT le possède bien
        require(idToMarketItem[itemId].owner == msg.sender, "You are not the owner of this NFT");
        idToMarketItem[itemId].inSell = true;
    }

    // Fonction pour acheter un NFT
    // @param nftContract: Adresse du contrat NFT
    // @param itemId: Id de l'item
    function buyNFT(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        // On vérifie que le prix envoyer par la personne appelant le smart contrat est égale au prix du NFT
        require(msg.value == price, "Please sumbit the asking price in order to complete the purchase");
        // On vérifie que le NFT est bien en vente
        require(idToMarketItem[itemId].inSell == true, "This NFT is not in the market");
        // On vérifie que la personne n'achète pas son propre NFT !
        require(idToMarketItem[itemId].owner != msg.sender, "You can't buy your own NFT");

        // On paye l'ancien propriétaire
        idToMarketItem[itemId].owner.transfer(msg.value);
        // On transfère le nft au nouveau propriétaire
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        // On met à jour le nouveau propriétaire
        idToMarketItem[itemId].owner = payable(msg.sender);
        // On rajoute a la liste des anciens propriétaires le nouveau propriétaire
        idToMarketItem[itemId].oldOwner.push(msg.sender);
        // On rajoute a la liste des anciens prix le prix auquel c'est vendu le NFT
        idToMarketItem[itemId].oldPriceSold.push(msg.value);
        // On met à jour le statut de l'item
        idToMarketItem[itemId].inSell = false;
        // On incrémente le nombre d'NFT vendu
        _itemsSold.increment();
        _itemsInSell.decrement();
    }

    // Fonction pour lister tous les items en vente sur le market
    // On va simplement chercher tous les items avec le inSell = true
    function fetchMarketItemsInSell() public view returns (MarketItem[] memory) {
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](_itemsInSell.current());
        for(uint i = 0; i< _itemIds.current(); i++){
            if(idToMarketItem[i + 1].inSell == true){
                uint currenId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currenId];
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
            if(idToMarketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].owner == msg.sender){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
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
            if(idToMarketItem[i + 1].creator == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i + 1].creator == msg.sender){
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}