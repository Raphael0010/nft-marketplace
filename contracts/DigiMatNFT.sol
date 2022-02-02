// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DigiMatNFT is ERC721Burnable, ERC721Enumerable, Ownable {
    uint256 public tokenCounter = 0;

    // NFT data
    mapping(uint256 => uint256) public amount;
    mapping(uint256 => uint256) public matureTime;

    constructor() ERC721("DigiMatNFT", "DMT") {
    }

    function mint(address _recipient, uint256 _amount, uint256 _matureTime) public onlyOwner returns (uint256) {
        _mint(_recipient, tokenCounter);
        amount[tokenCounter] = _amount;
        matureTime[tokenCounter] = _matureTime;

        tokenCounter++;
        return tokenCounter - 1;
    }

    function tokenDetails(uint256 _tokenId) public view returns (uint256, uint256) {
        require (_exists(_tokenId), "Query for nonexistent token");
        return (amount[_tokenId], matureTime[_tokenId]);
    }

    function contractAddress() public view returns (address) {
        return address(this);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override(ERC721, ERC721Enumerable) { }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) { }

}