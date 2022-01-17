# NFT Marketplace, built on  ERC721
 - Using Maticvigil rpc  
 - Using Polygon L2
 - Using HardHat

## SmartContract
Struct of the contract  :
```
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
```

## Actual Coverage :

```
√ Should create and list an NFT (140ms)
√ Should create an NFT and remove it from sales (101ms)
√ Should create an NFT and remove it from sales and re add it to sales (185ms)
√ Should buy a nft (150ms)
√ Should not buy is own nft (134ms)
√ Should not buy a nft who is not in sell
√ Should send the right price to buy the nft (39ms)
```

## Setup :

Add `.secret` file with the private key from MetaMask.  
Add `.appId` with AppId create from maticvigil  
Run ``yarn`` inside the project and ```yarn hardhat test```  

## Credit :
Inspiration for the project : https://www.youtube.com/watch?v=GKJBEEXUha0