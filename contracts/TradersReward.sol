// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TraderRewards is Ownable {
    using SafeERC20 for IERC20;

    struct RewardInfo {
        address trader;
        uint256 reward;
    }

    mapping(uint256 => RewardInfo[]) public epochRewards; // Mapping from epoch to rewards
    uint256 public currentEpoch;
    IERC20 public rewardToken; // The token used for rewards
    address public fundAddress; // Address where unclaimed rewards are sent

    /// @notice Keeper register. Return true if 'address' is a keeper.
    mapping(address => bool) public isKeeper;

    event RewardsUpdated(uint256 epoch, RewardInfo[] rewards);
    event RewardClaimed(address indexed trader, uint256 reward);
    event FundAddressUpdated(address newFundAddress);
    event UnclaimedRewardsWithdrawn(uint256 epoch, uint256 amount);

    modifier onlyKeeper {
        require(msg.sender == owner() || isKeeper[msg.sender],'not keeper'); 
        _;
    }
    constructor(IERC20 _rewardToken, address _fundAddress) {
        rewardToken = _rewardToken;
        fundAddress = _fundAddress;
    }

    /// @notice add keepers
    function addKeeper(address[] memory _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for(i; i < len; i++){
            address _keeper = _keepers[i];
            if(!isKeeper[_keeper]){
                isKeeper[_keeper] = true;
            }
        }
    }
    /// @notice remove keepers
    function removeKeeper(address[] memory _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for(i; i < len; i++){
            address _keeper = _keepers[i];
            if(isKeeper[_keeper]){
                isKeeper[_keeper] = false;
            }
        }
    }  
    function updateFundAddress(address _newFundAddress) external onlyOwner {
        require(_newFundAddress != address(0), "Invalid address");
        fundAddress = _newFundAddress;
        emit FundAddressUpdated(_newFundAddress);
    }

    function updateRewards(RewardInfo[] calldata rewards) external onlyKeeper {
        uint256 lastEpoch = currentEpoch;
        currentEpoch += 1; // Move to the next epoch

        delete epochRewards[currentEpoch]; // Clear any existing rewards for safety
        for (uint256 i = 0; i < rewards.length; i++) {
            epochRewards[currentEpoch].push(rewards[i]);
        }

        if (lastEpoch > 1) {
            withdrawUnclaimedRewards(lastEpoch - 1);
        }

        emit RewardsUpdated(currentEpoch, rewards);
    }

    function claimReward(uint256 epoch) external {
        require(epoch < currentEpoch, "Cannot claim for ongoing or future epochs");

        RewardInfo[] storage rewards = epochRewards[epoch];
        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i].trader == msg.sender) {
                uint256 rewardAmount = rewards[i].reward;
                require(rewardToken.balanceOf(address(this)) >= rewardAmount, "Insufficient reward tokens");
                rewardToken.transfer(msg.sender, rewardAmount);

                delete rewards[i];
                emit RewardClaimed(msg.sender, rewardAmount);
                return;
            }
        }
        revert("No rewards found for caller in specified epoch");
    }

    function withdrawUnclaimedRewards(uint256 epoch) internal {
        RewardInfo[] storage rewards = epochRewards[epoch];
        uint256 totalUnclaimed = 0;

        for (uint256 i = 0; i < rewards.length; i++) {
            totalUnclaimed += rewards[i].reward;
            delete rewards[i];
        }

        if (totalUnclaimed > 0) {
            rewardToken.transfer(fundAddress, totalUnclaimed);
            emit UnclaimedRewardsWithdrawn(epoch, totalUnclaimed);
        }

        delete epochRewards[epoch];
    }

    // View function to fetch rewards for a specific epoch
    function getRewardsForEpoch(uint256 epoch) external view returns (RewardInfo[] memory) {
        return epochRewards[epoch];
    }

    // View function to check a user's claimable reward for a specific epoch
    function checkReward(address user, uint256 epoch) external view returns (uint256) {
        RewardInfo[] memory rewards = epochRewards[epoch];
        for (uint256 i = 0; i < rewards.length; i++) {
            if (rewards[i].trader == user) {
                return rewards[i].reward;
            }
        }
        return 0;
    }

    // View function to see the current reward token balance of the contract
    function rewardTokenBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
}

