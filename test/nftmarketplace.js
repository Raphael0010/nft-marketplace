const { expect } = require("chai");
const { ethers } = require("hardhat");

let nftContractAddress = null;
let marketReady = null;
let nftReady = null;

before(async () => {
  const Market = await ethers.getContractFactory("NFTMarket");
  const market = await Market.deploy();
  marketReady = await market.deployed();
  const marketAddress = market.address;

  const NFT = await ethers.getContractFactory("NFT");
  const nft = await NFT.deploy(marketAddress);
  nftReady = await nft.deployed()
  nftContractAddress = nft.address;
})

// (Value: msg.value(montant envoyé au smartcontrat) lors de l'appel du smartContract)
describe("NFTMarket", async function () {
  it("Should create and list an NFT", async function () {
    let listingPrice = await marketReady.getListingPrice();
    listingPrice = listingPrice.toString();
    const price = listingPrice;

    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 1, price, {value : listingPrice});

    // Je vérifie que mon NFT est bien dans la liste
    const items = await marketReady.fetchMarketItemsInSell();
    expect(items[0].nftContract).to.equal(nftContractAddress);

    // Je le retire de la liste des ventes pour la suite des tests
    await marketReady.removeNFTFromMarket(1);
  });

  it("Should create an NFT and remove it from sales", async function () {
    let listingPrice = await marketReady.getListingPrice();
    listingPrice = listingPrice.toString();
    const price = listingPrice;

    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 2, price, {value : listingPrice});
    
    // Je remove le NFT de la liste des ventes
    await marketReady.removeNFTFromMarket(2);

    // Je vérifie que mon NFT est bien dans la liste
    const items = await marketReady.fetchMarketItemsInSell();
    expect(items.length).to.equal(0);
  });

  it("Should create an NFT and remove it from sales and re add it to sales", async function () {
    let listingPrice = await marketReady.getListingPrice();
    listingPrice = listingPrice.toString();
    const price = listingPrice;

    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 3, price, {value : listingPrice});
    
    // Je remove le NFT de la liste des ventes
    await marketReady.removeNFTFromMarket(3);

    // Je le rajoute dans la liste des NFT disponible a la vente
    await marketReady.addNFTToMarket(3);

    // Je vérifie que mon NFT est bien dans la liste
    const items = await marketReady.fetchMarketItemsInSell();
    expect(items.length).to.equal(1);
  });

  it("Should buy a nft", async function () {
    let listingPrice = await marketReady.getListingPrice();
    listingPrice = listingPrice.toString();
    const price = listingPrice;
    
    const [_,buyerAddress] = await ethers.getSigners();

    // Je récupère mes NFT, actuellement avec les tests du haut je dois en avoir 3
    const before = await marketReady.fetchMyNFTs();
    expect(before.length).to.equal(3);

    await marketReady.connect(buyerAddress).buyNFT(nftContractAddress, 3, {value: price})

    // Je récupère mes NFT, une personne m'a acheter un NFT il doit m'en rester 2
    const after = await marketReady.fetchMyNFTs();
    expect(after.length).to.equal(2);
    
  });

  // TODO: Il faut tester qu'on ne peut pas acheter son propre NFT
  // TODO: Il faut tester qu'on ne peut pas acheter un NFT qui n'est pas vente !
  // TODO: Il faut tester que le buyer envoie bien le bon prix du NFT
});
