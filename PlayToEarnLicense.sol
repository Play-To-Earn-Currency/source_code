// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.31;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract PlayToEarnLicense is
    ERC721("Play To Earn LICENSE", "PTELIC"),
    ERC721URIStorage,
    ERC721Enumerable,
    Ownable(msg.sender)
{
    uint256 public constant REWARD_COOLDOWN = 24 hours; // Cooldown per creation

    uint256 public lastTimestamp = block.timestamp; // Stores the timestamp from last nft
    uint256 public nextTokenId; // NFT Token ID

    string public imageUrl = "https://playtoearncurrency.org/license/";
    string public imageExtension = ".png";
    string public projectUrl = "https://playtoearncurrency.org/";

    event NFTBurned(address indexed account, uint256 tokenId); // Burn event
    event NFTMinted(uint256 tokenId); // NFT Minted

    function mintNFT() external onlyOwner returns (uint256) {
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

    function burnNFT(uint256 tokenId) external {
        // Check if the current wallet owns the nft
        require(
            ownerOf(tokenId) == msg.sender,
            "You can only burn your own NFTs"
        );

        // Burning
        _burn(tokenId);

        emit NFTBurned(msg.sender, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");

        string memory image = string(
            abi.encodePacked(
                imageUrl,
                Strings.toString(tokenId),
                imageExtension
            )
        );

        string memory json = string(
            abi.encodePacked(
                "{",
                '"name":"License #',
                Strings.toString(tokenId),
                '",',
                '"image":"',
                image,
                '",',
                '"external_url":"',
                projectUrl,
                '",',
                '"attributes":[',
                '{"trait_type":"Type","value":"License"}',
                " ]",
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function updateURLs(
        string calldata newImageUrl,
        string calldata newImageExtension,
        string calldata newProjectUrl
    ) external onlyOwner {
        imageUrl = newImageUrl;
        imageExtension = newImageExtension;
        projectUrl = newProjectUrl;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
