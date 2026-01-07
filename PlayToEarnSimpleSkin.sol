// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.31;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IERC20Burnable is IERC20 {
    function burnToken(uint256 amount) external;
}

contract PlayToEarnSimpleSkin is
    ERC721("Play To Earn Simple Skin", "PTESK"),
    ERC721URIStorage,
    ERC721Enumerable,
    Ownable(msg.sender)
{
    address public CURRENCY_ADDRESS =
        0x0000000000000000000000000000000000000000; // The current Currency Address

    uint256[] public availableTokens = [1]; // Available tokens to user earn in mint
    uint256[] public rarityCostIndex = [20000000000000000000]; // The cost for rarity
    uint16[] public rarityChanceIndex = [100]; // The chance to receive a better rarity
    uint256 public maxRarityIndex = 0; // The max rarity value to user receive

    uint256 public nextTokenId; // NFT Token ID

    string public imageUrl = "https://playtoearncurrency.org/simpleskin/";
    string public imageExtension = ".png";
    string public projectUrl = "https://playtoearncurrency.org/";

    event NFTBurned(address indexed account, uint256 tokenId); // Burn event
    event NFTMinted(address indexed account, uint256 tokenId, uint256 rarity); // NFT Minted

    function getAllowance() external view returns (uint256) {
        return
            IERC20Burnable(CURRENCY_ADDRESS).allowance(
                msg.sender,
                address(this)
            );
    }

    mapping(address => bytes32) public addressToHash;
    function requestMintNFT(uint256 secretHash) external {
        require(addressToHash[msg.sender] == bytes32(0), "Already requested");

        bytes32 userSecret = keccak256(
            abi.encodePacked(secretHash, block.prevrandao)
        );

        addressToHash[msg.sender] = userSecret;
    }

    function mintNFT(uint256 rarity) external payable returns (uint256) {
        // Check secret
        require(
            addressToHash[msg.sender] != bytes32(0),
            "No hash committed yet"
        );
        bytes32 secretHash = addressToHash[msg.sender];

        // Check rarity
        require(rarity <= maxRarityIndex, "Invalid rarity number");

        // Getting the nft cost
        uint256 cost = rarityCostIndex[rarity];

        // Allowance check
        uint256 userAllowance = IERC20Burnable(CURRENCY_ADDRESS).allowance(
            msg.sender,
            address(this)
        );
        require(
            userAllowance >= cost,
            string(
                abi.encodePacked(
                    "Insufficient allowance, you must approve: ",
                    Strings.toString(cost),
                    ", to ",
                    Strings.toHexString(uint160(address(this)), 20)
                )
            )
        );

        // Check user balance
        uint256 userBalance = IERC20Burnable(CURRENCY_ADDRESS).balanceOf(
            address(msg.sender)
        );
        require(userBalance >= cost, "Not enough Play To Earn Currency");

        // Transfer to the contract
        IERC20Burnable(CURRENCY_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            cost
        );

        // Burning the received coins
        IERC20Burnable(CURRENCY_ADDRESS).burnToken(cost);

        // Generating token
        generateNFT(msg.sender, rarityChanceIndex[rarity], secretHash);

        // Removing the security hash
        delete addressToHash[msg.sender];

        nextTokenId++;
        return nextTokenId - 1;
    }

    function generateNFT(
        address receiverAddress,
        uint16 rollChance,
        bytes32 secretHash
    ) internal {
        // Generate rarity
        uint256 rarity = 0;
        for (uint256 i = 0; i < 10; i++) {
            uint256 chance = getRandomNumber(1000, secretHash);
            if (chance <= rollChance) {
                rarity++;
            }
        }
        // Generate the skin id
        uint256 skinId = getRandomNumber(availableTokens[rarity], secretHash);

        // Generate token data
        string memory metadataURI = string(
            abi.encodePacked(
                Strings.toString(rarity),
                "-",
                Strings.toString(skinId)
            )
        );

        // Generating token
        _safeMint(receiverAddress, nextTokenId);
        _setTokenURI(nextTokenId, metadataURI);

        emit NFTMinted(receiverAddress, nextTokenId, rarity);
    }

    function getRandomNumber(
        uint256 max,
        bytes32 secretHash
    ) internal view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(secretHash, block.prevrandao))) %
            max;
    }

    function increaseTokenCount(uint8 rarity) external onlyOwner {
        require(rarity <= maxRarityIndex, "Invalid rarity number");
        availableTokens[rarity]++;
    }

    function increaseRarityCount(
        uint256 rarityCost,
        uint16 rarityChance
    ) external onlyOwner {
        availableTokens.push(1);
        rarityCostIndex.push(rarityCost);
        rarityChanceIndex.push(rarityChance);
        maxRarityIndex++;
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

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");

        string memory skinid = super.tokenURI(tokenId);

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
                '"name":"Skin #',
                Strings.toString(tokenId),
                '",',
                '"image":"',
                image,
                '",',
                '"external_url":"',
                projectUrl,
                '",',
                '"attributes":[',
                '{"trait_type":"Skin","value":"',
                skinid,
                '"}',
                "]",
                "}"
            )
        );

        return json;
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
