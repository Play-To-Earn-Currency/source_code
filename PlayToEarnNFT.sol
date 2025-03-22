// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/token/ERC721/ERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/access/Ownable.sol";

contract PlayToEarnNFT is
    ERC721("Play To Earn NFT", "PTENFT"),
    Ownable(address(0x518Ab58fD7ddcFE5f8Ee02a59472Df3220a1d86F))
{
    uint256 public constant REWARD_COOLDOWN = 24 hours; // Cooldown per creation

    uint256 public lastTimestamp = block.timestamp; // Stores the timestamp from last nft
    uint256 public nextTokenId; // NFT Token ID

    event NFTBurned(address indexed account, uint256 tokenId); // Burn event
    event NFTMinted(uint256 tokenId); // NFT Minted

    function mintNFT() public onlyOwner returns (uint256) {
        require(
            block.timestamp >= lastTimestamp + REWARD_COOLDOWN,
            "NFTs can only be minted every 24 hour"
        );

        // Update the last time stamp
        lastTimestamp = block.timestamp;

        // Give nft to the owner
        _safeMint(owner(), nextTokenId);
        // Increase the NFT Token ID
        nextTokenId++;

        emit NFTMinted(nextTokenId - 1);

        return nextTokenId - 1;
    }

    function burnNFT(uint256 tokenId) public {
        // Check if the current wallet owns the nft
        require(
            ownerOf(tokenId) == msg.sender,
            "You can only burn your own NFTs"
        );

        // Burning
        _burn(tokenId);

        emit NFTBurned(msg.sender, tokenId);
    }
}