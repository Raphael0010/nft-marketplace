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
√ Should create and list an NFT (184ms)
√ Should create an NFT and remove it from sales (152ms)
√ Should create an NFT and remove it from sales and re add it to sales (190ms)
√ Should buy a nft (191ms)
```

## Setup :

Add `.secret` file with the private key from MetaMask.  
Add `.appId` with AppId create from maticvigil  
Run ``yarn`` inside the project and ```yarn hardhat test```  

## Credit :
Inspiration for the project : https://www.youtube.com/watch?v=GKJBEEXUha0