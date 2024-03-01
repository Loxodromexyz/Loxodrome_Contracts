// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TraderRewards is Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => bytes32) public epochMerkleRoots; // Mapping from epoch to Merkle Root
    mapping(uint256 => string) public epochDataURIs; // Epoch => IPFS URI for data
    mapping(address => mapping(uint256 => uint256)) public claimedRewards;
    mapping(uint256 => uint256) public totalRewardsPerEpoch;
    mapping(uint256 => uint256) public totalClaimedPerEpoch;

    uint256 public currentEpoch;
    IERC20 public rewardToken; // The token used for rewards
    address public fundAddress; // Address where unclaimed rewards are sent
    uint256 public CLAIM_DEADLINE = 2; // Users have 2 epochs to claim their rewards

    mapping(address => bool) public isKeeper;

    uint256 public lastUpdateTime; // Tracks the last time rewards were updated
    uint256 public constant EPOCH_DURATION = 86400 * 7; // Duration of each epoch in seconds

    event RewardsUpdated(uint256 epoch, bytes32 merkleRoot);
    event RewardClaimed(address indexed trader, uint256 reward);
    event FundAddressUpdated(address newFundAddress);
    event DeadlineUpdated(uint256 newDeadline);
    event UnclaimedRewardsWithdrawn(uint256 epoch, uint256 amount);
    event EpochDataURIUpdated(uint256 indexed epoch, string dataURI);

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
    function updateDeadline(uint256 _epochNumber) external onlyOwner {
        require(_epochNumber >= 2, "claim period less then 2 epoch");
        CLAIM_DEADLINE = _epochNumber;
        emit DeadlineUpdated(_epochNumber);
    }
    function updateEpochDataURI(uint256 epoch, string calldata newDataURI) external onlyOwner {
        require(epoch <= currentEpoch, "Cannot update future epochs");
        require(bytes(newDataURI).length > 0, "Invalid IPFS URI");

        epochDataURIs[epoch] = newDataURI;

        emit EpochDataURIUpdated(epoch, newDataURI);
    }
    function updateRewards(bytes32 merkleRoot) external onlyKeeper {
        //require(block.timestamp >= lastUpdateTime + EPOCH_DURATION, "updateRewards can only be called once per epoch");
        currentEpoch += 1; // Move to the next epoch
        epochMerkleRoots[currentEpoch] = merkleRoot;
        lastUpdateTime = block.timestamp;

        emit RewardsUpdated(currentEpoch, merkleRoot);
    }

     function claimReward(uint256 epoch, uint256 rewardAmount, bytes32[] calldata merkleProof) external {
        require(epoch < currentEpoch, "Cannot claim for ongoing or future epochs");
        require(currentEpoch <= epoch + CLAIM_DEADLINE, "Claim deadline exceeded for this epoch");
        require(claimedRewards[msg.sender][epoch] == 0, "Reward already claimed for this epoch");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, rewardAmount));
        require(verify(merkleProof, epochMerkleRoots[epoch], leaf), "Invalid proof");
        claimedRewards[msg.sender][epoch] = rewardAmount;
        rewardToken.safeTransfer(msg.sender, rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
    ///@notice in case token get stuck.
    function withdrawERC20() external onlyOwner {
        uint256 _balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(fundAddress, _balance);
    }

    // View function to see the current reward token balance of the contract
    function rewardTokenBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
}

