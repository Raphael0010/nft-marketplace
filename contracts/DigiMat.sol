// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import  "./DigiMatNFT.sol";

contract DigiMat is Ownable {

    DigiMatNFT public digimatNFT;
    bool public initialized = false;

    event Escrowed(address _from, address _to, uint256 _amount, uint256 _matureTime);
    event Redeemed(address _recipient, uint256 _amount);
    event Initialized(address _escrowNft);

    modifier isInitialized() {
        require(initialized, "Contract is not yet initialized");
        _;
    }

    function initialize(address _escrowNftAddress) external onlyOwner {
        require(!initialized, "Contract already initialized.");
        digimatNFT = DigiMatNFT(_escrowNftAddress);
        initialized = true;

        emit Initialized(_escrowNftAddress);
    }

    function escrowEth(address _recipient, uint256 _duration) external payable isInitialized {
        require(_recipient != address(0), "Cannot escrow to zero address.");
        require(msg.value > 0, "Cannot escrow 0 ETH.");

        uint256 amount = msg.value;
        uint256 matureTime = block.timestamp + _duration;

        digimatNFT.mint(_recipient, amount, matureTime);

        emit Escrowed(msg.sender,
            _recipient,
            amount,
            matureTime);
    }

    function redeemEthFromEscrow(uint256 _tokenId) external isInitialized {
        require(digimatNFT.ownerOf(_tokenId) == msg.sender, "Only the owner can redeem.");
            
        (uint256 amount, uint256 matureTime) = digimatNFT.tokenDetails(_tokenId);
        require(matureTime <= block.timestamp, "Escrow period not expired.");

        digimatNFT.burn(_tokenId);

        (bool success, ) = msg.sender.call{value: amount}("");

        require(success, "Transfer failed.");

        emit Redeemed(msg.sender, amount);
    }

    function redeemAllAvailableEth() external isInitialized {
        uint256 nftBalance = digimatNFT.balanceOf(msg.sender);
        require(nftBalance > 0, "No NFT to redeem.");

        uint256 totalAmount = 0;

        for(uint256 i = 0; i < nftBalance; i++) {
            uint256 tokenId = digimatNFT.tokenOfOwnerByIndex(msg.sender, i);
            (uint256 amount, uint256 matureTime) = digimatNFT.tokenDetails(tokenId);
            

            if(matureTime <= block.timestamp){
                digimatNFT.burn(tokenId);
                totalAmount += amount;
            }
        }

        require(totalAmount > 0, "No Ether to redeem.");

        (bool success, ) = msg.sender.call{value: totalAmount}("");

        require(success, "Transfer failed.");

        emit Redeemed(msg.sender, totalAmount);
    }

    function contractAddress() public view returns (address) {
        return address(this);
    }

}