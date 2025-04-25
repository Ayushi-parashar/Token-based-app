// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenGatedMembershipStore
 * @dev Contract for managing membership tiers based on token holdings
 */
contract TokenGatedMembershipStore is Ownable {
    // Token used for gating membership
    IERC20 public membershipToken;
    
    // Membership tier configuration
    struct MembershipTier {
        string name;
        uint256 tokenRequirement;
        uint256 price;
        bool active;
    }
    
    // Mapping of tier ID to membership tier details
    mapping(uint256 => MembershipTier) public membershipTiers;
    
    // Mapping of user addresses to their membership tier ID
    mapping(address => uint256) public userMemberships;
    
    // Events
    event MembershipPurchased(address indexed user, uint256 tierId);
    event TierConfigured(uint256 tierId, string name, uint256 tokenRequirement, uint256 price);
    event MembershipTokenChanged(address newTokenAddress);
    
    /**
     * @dev Constructor sets the membership token and initial owner
     * Sample token address is provided for demonstration
     * In production, replace with actual token address
     */
    constructor() Ownable(msg.sender) {
        // Sample token address (for demonstration - this is USDC on Ethereum Mainnet)
        address sampleTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        
        membershipToken = IERC20(sampleTokenAddress);
        
        // Initialize with basic tiers
        _configureTier(1, "Bronze", 100 * 10**6, 0.01 ether); // Adjusted decimals for USDC
        _configureTier(2, "Silver", 500 * 10**6, 0.05 ether);
        _configureTier(3, "Gold", 1000 * 10**6, 0.1 ether);
    }
    
    /**
     * @dev Purchase a membership tier
     * @param tierId The ID of the tier to purchase
     */
    function purchaseMembership(uint256 tierId) external payable {
        MembershipTier memory tier = membershipTiers[tierId];
        require(tier.active, "Tier not available");
        require(msg.value >= tier.price, "Insufficient payment");
        require(
            membershipToken.balanceOf(msg.sender) >= tier.tokenRequirement,
            "Insufficient token balance"
        );
        
        // Assign membership tier to the user
        userMemberships[msg.sender] = tierId;
        
        // Emit event
        emit MembershipPurchased(msg.sender, tierId);
        
        // Refund excess payment if any
        if (msg.value > tier.price) {
            payable(msg.sender).transfer(msg.value - tier.price);
        }
    }
    
    /**
     * @dev Configure a membership tier (owner only)
     * @param tierId The ID of the tier to configure
     * @param name The name of the tier
     * @param tokenRequirement The number of tokens required to be eligible
     * @param price The price in ETH to purchase the membership
     */
    function configureTier(
        uint256 tierId,
        string calldata name,
        uint256 tokenRequirement,
        uint256 price
    ) external onlyOwner {
        _configureTier(tierId, name, tokenRequirement, price);
    }
    
    /**
     * @dev Internal function to configure a membership tier
     */
    function _configureTier(
        uint256 tierId,
        string memory name,
        uint256 tokenRequirement,
        uint256 price
    ) internal {
        membershipTiers[tierId] = MembershipTier({
            name: name,
            tokenRequirement: tokenRequirement,
            price: price,
            active: true
        });
        
        emit TierConfigured(tierId, name, tokenRequirement, price);
    }
    
    /**
     * @dev Change the membership token address (owner only)
     * @param newTokenAddress The address of the new membership token
     */
    function setMembershipToken(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        membershipToken = IERC20(newTokenAddress);
        emit MembershipTokenChanged(newTokenAddress);
    }
    
    /**
     * @dev Withdraw contract funds (owner only)
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
