// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("DigiMatNFT","DMT"){
    }

    //uri de l'image avec les metadata du nft build via infura
    function mint(string memory metadataUri) public returns (uint){
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);
        _setTokenURI(id, metadataUri);
        setApprovalForAll(address(this), true);
        return id;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }
}

// https://medium.com/blockchain-manchester/erc-721-metadata-standards-and-ipfs-94b01fea2a89