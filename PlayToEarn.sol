// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/access/Ownable.sol";
import "./Play_To_Earn_NFT.sol";

contract PlayToEarnCoin is
    ERC20("Play To Earn Coin", "PTE"),
    Ownable(address(0x518Ab58fD7ddcFE5f8Ee02a59472Df3220a1d86F))
{
    PlayToEarnNFT private _playToEarnNFT =
        PlayToEarnNFT(address(0xAb4D78cCe19BEb9265C92B3a00de7994b28B0b6C)); // Official NFT Address

    uint256 public constant REWARD_COOLDOWN = 24 hours; // Cooldown per address
    uint256 public constant REDUCTION_RATE = 99995; // How much "tokensPerDay" will be reduced every day

    uint256 public tokensPerDay = 100 * 10**18; // Starting Tokens Per Day "100"

    uint256 public lastReductionTimestamp; // Reduction Cooldown
    address[] public addressOnCooldown; // Stores the cooldown address
    mapping(address => uint256) public addressTimestampCooldown; // Stores the timestamp cooldown address

    event TokensBurned(address indexed account, uint256 amount); // Burn event
    event TokenRewardClaimed(address indexed account, uint256 amount); // Reward Claimed

    uint256 public lastCleanupTimestamp; // Timestamp of the last cleanup call

    function rewardTokens() public {
        // Get nft amount
        uint256 balance = _playToEarnNFT.balanceOf(msg.sender);

        // Check if no balance
        require(balance > 0, "You must own at least one NFT to claim rewards");

        // Check if 24 hours have passed since last reward
        require(
            block.timestamp >=
                addressTimestampCooldown[msg.sender] + REWARD_COOLDOWN,
            "Cannot reward the same wallet within 24 hours"
        );

        // Apply reduction if 24 hours have passed
        if (block.timestamp >= lastReductionTimestamp + REWARD_COOLDOWN) {
            tokensPerDay = (tokensPerDay * REDUCTION_RATE) / 100000; // Reduce by 0.005%
            lastReductionTimestamp = block.timestamp; // Update last reduction time
        }

        // Give tokens for the rewarded wallet
        for (uint256 i = 0; i < balance; i++) {
            _mint(msg.sender, tokensPerDay);
        }

        // Update the last reward timestamp for the given wallet
        addressTimestampCooldown[msg.sender] = block.timestamp;
        addressOnCooldown.push(msg.sender);

        emit TokenRewardClaimed(msg.sender, tokensPerDay);
    }

    function cleanupRewardAddresses() public onlyOwner {
        // Ensure this function is only called once per day
        require(
            block.timestamp >= lastCleanupTimestamp + REWARD_COOLDOWN,
            "Cleanup can only be called once every 24 hours"
        );

        uint256 i = 0;

        // Loop through all addresses on cooldown
        while (i < addressOnCooldown.length) {
            // Get the current address from the cooldown list
            address wallet = addressOnCooldown[i];
            // Get the last reward timestamp of the current address
            uint256 cooldownTime = addressTimestampCooldown[wallet];

            // Check if the cooldown period has passed for the current address
            if (block.timestamp >= cooldownTime + REWARD_COOLDOWN) {
                // Remove it from mapping address
                delete addressTimestampCooldown[wallet];

                // Remove it from array address
                addressOnCooldown[i] = addressOnCooldown[
                    addressOnCooldown.length - 1
                ];
                addressOnCooldown.pop();

                // Reduce the index so it can be read again in this index
                i--;
            }

            i++;
        }

        // Update the last cleanup timestamp
        lastCleanupTimestamp = block.timestamp;
    }

    function burnCoin(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
}