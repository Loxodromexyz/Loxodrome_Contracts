// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SignedSafeMath.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/ILoxo.sol";

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    struct UserInfo {
        uint256 amount;
        int256 rewardDebtWIOTX;
        int256 rewardDebtLOXO;
        int256 rewardDebt;
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndices;
    }

    struct PoolInfo {
        uint256 accRewardPerShareWIOTX;
        uint256 accRewardPerShareLOXO;
        uint256 lastRewardTime;
    }
    /// @notice lock period is set to 2 years.
    uint internal constant LOCK = 86400 * 7 * 52 * 2;
    
    uint internal LIMIT = 10 * 1e18;
    uint internal RATIO = 500;// 5%
    uint internal constant PRECISION = 1000;

    /// @notice Address of WIOTX contract.
    IERC20 public WIOTX;
    /// @notice Address of the NFT token for each MCV2 pool.
    IERC721 public NFT;

    /// @notice Info of each MCV2 pool.
    PoolInfo public poolInfo;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice Info of each user that stakes nft tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice Keeper register. Return true if 'address' is a keeper.
    mapping(address => bool) public isKeeper;

    uint256 public rewardPerSecond;
    uint256 public rewardPerSecondLOXO;
    uint256 private ACC_WIOTX_PRECISION;

    // 
    ILoxo public immutable LOXO;
    IVotingEscrow public immutable _ve;

    uint256 public distributePeriod;
    uint256 public lastDistributedTime;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 pendingWIOTX, uint256 pendingLOXO);
    event LogUpdatePool(
        uint256 lastRewardTime,
        uint256 nftSupply,
        uint256 rewardPerSecondWIOTX,
        uint256 rewardPerSecondLOXO 
    );
    event LogRewardPerSecond(
        uint256 rewardPerSecondWIOTX, 
        uint256 rewardPerSecondLOXO 
    );
    event LogLimit(
        uint256 limitToLock
    );


    modifier onlyKeeper {
        require(msg.sender == owner() || isKeeper[msg.sender],'not keeper'); 
        _;
    }

    constructor(
        IERC20 _WIOTX,
        address __ve, // the ve(3,3) system that will be locked into
        IERC721 _NFT
        ) {
        
        WIOTX = _WIOTX;
        LOXO = ILoxo(IVotingEscrow(__ve).token());
        _ve = IVotingEscrow(__ve);
        NFT = _NFT;
        distributePeriod = 1 weeks;
        ACC_WIOTX_PRECISION = 1e12;
        poolInfo = PoolInfo({
            lastRewardTime: block.timestamp,
            accRewardPerShareWIOTX: 0,
            accRewardPerShareLOXO:0
        });
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


    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Reward to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond, uint256 _rewardPerSecondNewToken) public onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
        rewardPerSecondLOXO = _rewardPerSecondNewToken; // Add this line
        emit LogRewardPerSecond(_rewardPerSecond, _rewardPerSecondNewToken);
    }
    
    function setLimit(uint _limitToLock) public onlyOwner {
        LIMIT = _limitToLock;
        emit LogLimit(_limitToLock);
    }

    function setDistributionRate(uint256 amount, uint256 amountLOXO) public onlyKeeper {
        updatePool();
        uint256 notDistributed;
        if (lastDistributedTime > 0 && block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime.sub(block.timestamp);
            notDistributed = rewardPerSecond.mul(timeLeft);
        }

        amount = amount.add(notDistributed);
        uint256 _rewardPerSecond = amount.div(distributePeriod);
        rewardPerSecond = _rewardPerSecond;
        lastDistributedTime = block.timestamp.add(distributePeriod);
        amountLOXO = amountLOXO.add(notDistributed);
        uint256 _rewardPerSecondLOXO = amountLOXO.div(distributePeriod);
        rewardPerSecondLOXO = _rewardPerSecondLOXO;
        emit LogRewardPerSecond(_rewardPerSecond, _rewardPerSecondLOXO);
    }

    /// @notice View function to see pending WIOTX and LOXO on frontend.
    /// @param _user Address of user.
    /// @return pendingWIOTX and pendingLOXO for a given user.
    function pendingReward(address _user)
        external
        view
        returns (uint256 pendingWIOTX, uint256 pendingLOXO)
    {
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 nftSupply = NFT.balanceOf(address(this));

        uint256 accRewardPerShareWIOTX = pool.accRewardPerShareWIOTX;
        uint256 accRewardPerShareLOXO = pool.accRewardPerShareLOXO;

        if (block.timestamp > pool.lastRewardTime && nftSupply != 0) {
            uint256 timeElapsed = block.timestamp.sub(pool.lastRewardTime);
            uint256 rewardWIOTX = timeElapsed.mul(rewardPerSecond);
            uint256 rewardLOXO = timeElapsed.mul(rewardPerSecondLOXO);

            accRewardPerShareWIOTX = accRewardPerShareWIOTX.add(
                rewardWIOTX.mul(ACC_WIOTX_PRECISION) / nftSupply
            );
            accRewardPerShareLOXO = accRewardPerShareLOXO.add(
                rewardLOXO.mul(ACC_WIOTX_PRECISION) / nftSupply
            );
        }

        pendingWIOTX = int256(
            user.amount.mul(accRewardPerShareWIOTX) / ACC_WIOTX_PRECISION
        ).sub(user.rewardDebtWIOTX).toUInt256();

        pendingLOXO = int256(
            user.amount.mul(accRewardPerShareLOXO) / ACC_WIOTX_PRECISION
        ).sub(user.rewardDebtLOXO).toUInt256();
    }

    /// @notice View function to see token Ids on frontend.
    /// @param _user Address of user.
    /// @return tokenIds Staked Token Ids for a given user.
    function stakedTokenIds(address _user)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = userInfo[_user].tokenIds;
    }

    /// @notice Update reward variables of the given pool.
    /// @return pool Returns the pool that was updated.
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;
        if (block.timestamp > pool.lastRewardTime) {
            uint256 nftSupply = NFT.balanceOf(address(this));
            if (nftSupply > 0) {
                uint256 timeElapsed = block.timestamp.sub(pool.lastRewardTime);
                uint256 rewardWIOTX = timeElapsed.mul(rewardPerSecond);
                uint256 rewardLOXO = timeElapsed.mul(rewardPerSecondLOXO);

                pool.accRewardPerShareWIOTX = pool.accRewardPerShareWIOTX.add(rewardWIOTX.mul(ACC_WIOTX_PRECISION).div(nftSupply));
                pool.accRewardPerShareLOXO = pool.accRewardPerShareLOXO.add(rewardLOXO.mul(ACC_WIOTX_PRECISION).div(nftSupply));
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo = pool;
            emit LogUpdatePool(
                pool.lastRewardTime,
                nftSupply,
                pool.accRewardPerShareWIOTX,
                pool.accRewardPerShareLOXO
            );
        }
    }

    /// @notice Deposit nft tokens to MCV2 for WIOTX allocation.
    /// @param tokenIds NFT tokenIds to deposit.
    function deposit(uint256[] calldata tokenIds) public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.amount = user.amount.add(tokenIds.length);
            user.rewardDebtWIOTX = user.rewardDebtWIOTX.add(int256(tokenIds.length.mul(pool.accRewardPerShareWIOTX) / ACC_WIOTX_PRECISION)
            );
            user.rewardDebtLOXO = user.rewardDebtLOXO.add(int256(tokenIds.length.mul(pool.accRewardPerShareLOXO) / ACC_WIOTX_PRECISION)
            );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(NFT.ownerOf(tokenIds[i]) == msg.sender, "This NTF does not belong to address");

            user.tokenIndices[tokenIds[i]] = user.tokenIds.length;
            user.tokenIds.push(tokenIds[i]);
            tokenOwner[tokenIds[i]] = msg.sender;

            NFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit Deposit(msg.sender, tokenIds.length, msg.sender);
    }

    /// @notice Withdraw NFT tokens from MCV2.
    /// @param tokenIds NFT token ids to withdraw.
    function withdraw(uint256[] calldata tokenIds) public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.rewardDebtWIOTX = user.rewardDebtWIOTX.sub(
        int256(tokenIds.length.mul(pool.accRewardPerShareWIOTX) / ACC_WIOTX_PRECISION)
        );
        user.rewardDebtLOXO = user.rewardDebtLOXO.sub(
            int256(tokenIds.length.mul(pool.accRewardPerShareLOXO) / ACC_WIOTX_PRECISION)
        );
        user.amount = user.amount.sub(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenOwner[tokenIds[i]] == msg.sender,
                "Nft Staking System: user must be the owner of the staked nft"
            );
            NFT.transferFrom(address(this), msg.sender, tokenIds[i]);
            uint256 lastTokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds[user.tokenIndices[tokenIds[i]]] = lastTokenId;
            user.tokenIndices[lastTokenId] = user.tokenIndices[tokenIds[i]];
            user.tokenIds.pop();
            delete user.tokenIndices[tokenIds[i]];
            delete tokenOwner[tokenIds[i]];
        }

        emit Withdraw(msg.sender, tokenIds.length, msg.sender);
    }

    /// @notice Harvest proceeds for transaction sender.
    function harvest() public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];
        int256 accumulatedWIOTX = int256(user.amount.mul(pool.accRewardPerShareWIOTX) / ACC_WIOTX_PRECISION);
        int256 accumulatedLOXO = int256(user.amount.mul(pool.accRewardPerShareLOXO) / ACC_WIOTX_PRECISION);

        uint256 pendingWIOTX = accumulatedWIOTX.sub(user.rewardDebtWIOTX).toUInt256();
        uint256 pendingLOXO = accumulatedLOXO.sub(user.rewardDebtLOXO).toUInt256();

        // Update user rewards debt
        user.rewardDebtWIOTX = accumulatedWIOTX;
        user.rewardDebtLOXO = accumulatedLOXO;

        // Transfer rewards
        if (pendingWIOTX > 0) {
            WIOTX.safeTransfer(msg.sender, pendingWIOTX);
        }
        if (pendingLOXO > 0) {
            if(pendingLOXO > LIMIT){
                LOXO.approve(address(_ve), pendingLOXO);
                _ve.create_lock_for((pendingLOXO.mul(RATIO) / PRECISION), LOCK, msg.sender);
                LOXO.transfer(msg.sender, (pendingLOXO.mul(1000 - RATIO) / PRECISION));
            }else {
                LOXO.transfer(msg.sender, pendingLOXO);
            }
         
        }

        emit Harvest(msg.sender, pendingWIOTX, pendingLOXO); // Update event accordingly

    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}