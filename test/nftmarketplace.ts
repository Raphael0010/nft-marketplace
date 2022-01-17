import chai, { expect } from "chai";
import chaiAsPromised from 'chai-as-promised';
import { Contract } from "ethers";
import { ethers } from "hardhat";

let nftContractAddress = "";
let marketReady: Contract;
let nftReady: Contract;
let price: "";

chai.use(chaiAsPromised)

before(async () => {
  const Market = await ethers.getContractFactory("NFTMarket");
  const market = await Market.deploy();
  marketReady = await market.deployed();
  const marketAddress = market.address;

  const NFT = await ethers.getContractFactory("NFT");
  const nft = await NFT.deploy(marketAddress);
  nftReady = await nft.deployed()
  nftContractAddress = nft.address;

  let listingPrice = await marketReady.getListingPrice();
  listingPrice = listingPrice.toString();
  price = listingPrice;
})

// (Value: msg.value(montant envoyé au smartcontrat) lors de l'appel du smartContract)
describe("NFTMarket", async function () {
  it("Should create and list an NFT", async function () {
    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 1, price, {value : price});

    // Je vérifie que mon NFT est bien dans la liste
    const items = await marketReady.fetchMarketItemsInSell();
    expect(items[0].nftContract).to.equal(nftContractAddress);

    // Je le retire de la liste des ventes pour la suite des tests
    await marketReady.removeNFTFromMarket(1);
  });

  it("Should create an NFT and remove it from sales", async function () {
    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 2, price, {value : price});
    
    // Je remove le NFT de la liste des ventes
    await marketReady.removeNFTFromMarket(2);

    // Je vérifie que mon NFT est bien dans la liste
    const items = await marketReady.fetchMarketItemsInSell();
    expect(items.length).to.equal(0);
  });

  it("Should create an NFT and remove it from sales and re add it to sales", async function () {
    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 3, price, {value : price});
    
    // Je remove le NFT de la liste des ventes
    await marketReady.removeNFTFromMarket(3);

    // Je le rajoute dans la liste des NFT disponible a la vente
    await marketReady.addNFTToMarket(3);

    // Je vérifie que mon NFT est bien dans la liste
    const items = await marketReady.fetchMarketItemsInSell();
    expect(items.length).to.equal(1);
  });

  it("Should buy a nft", async function () {
    const [_,buyerAddress] = await ethers.getSigners();

    // Je récupère mes NFT, actuellement avec les tests du haut je dois en avoir 3
    const before = await marketReady.fetchMyNFTs();
    expect(before.length).to.equal(3);

    await marketReady.connect(buyerAddress).buyNFT(nftContractAddress, 3, {value: price})

    // Je récupère mes NFT, une personne m'a acheter un NFT il doit m'en rester 2
    const after = await marketReady.fetchMyNFTs();
    expect(after.length).to.equal(2);
    
  });

  it("Should not buy is own nft", async function () {
    // Je créer mon NFT
    await nftReady.createToken("Mon jolie NFT");

    // Je le liste
    await marketReady.createAndListNFT(nftContractAddress, 4, price, {value : price});

    // Je récupère les NFT de la liste des ventes
    const nftInSell = await marketReady.fetchMarketItemsInSell();

    // Je récupère mon address
    const myAddress = await ethers.getSigner(nftInSell[0].owner);

    // J'essai d'acheter le nft avec son adresse de création
    const result = marketReady.connect(myAddress).buyNFT(nftContractAddress, 4, {value: price})
    await expect(result).to.be.rejectedWith(/You can't buy your own NFT/)

  });

  it("Should not buy a nft who is not in sell", async function () {
    const [_,buyerAddress] = await ethers.getSigners();

    const result =  marketReady.connect(buyerAddress).buyNFT(nftContractAddress, 3, {value: price})
    await expect(result).to.be.rejectedWith(/This NFT is not for sale/)

  });

  it("Should send the right price to buy the nft", async function () {
    const [_,buyerAddress] = await ethers.getSigners();

    const result =  marketReady.connect(buyerAddress).buyNFT(nftContractAddress, 4, {value: price+5})
    await expect(result).to.be.rejectedWith(/Please submit the asking price in order to complete the purchase/)

  });
});
