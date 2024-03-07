// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./libraries/Math.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/ILoxo.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";


// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract Minter is IMinter {
    
    bool public isFirstMint;

    uint internal EMISSION = 990;
    // TODO: Emission decay is 1% or 990/1000 or 99% of total weekly distribution
    uint internal constant TAIL_EMISSION = 2;
    uint internal REBASEMAX = 100; // 10%
    uint internal NFTStakerMAX = 50; // 5%
    uint internal TradersMAX = 40; // 4% 
    
    uint internal constant PRECISION = 1000;
    uint public teamRate;
    uint public constant MAX_TEAM_RATE = 50; // 5%

    uint internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    // TODO: weekly emission is 10M
    uint public weekly = 375_000 * 1e18; // represents a starting weekly emission of 2.6M Loxo (Loxo has 18 decimals)
    uint public active_period;
    uint internal constant LOCK = 86400 * 7 * 52 * 2;

    address internal initializer;
    address public team;
    address public pendingTeam;
    address public _NFTstakers_rewards;
    address public _Traders_rewards;
    
    ILoxo public immutable _Loxo;
    IVoter public _voter;
    IVotingEscrow public immutable _ve;
    IRewardsDistributor public immutable _rewards_distributor;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);
    event PeriodUpdated(uint active_period);

    constructor(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __rewards_distributor, // the distribution system that ensures users aren't diluted
        address __NFTstakers_rewards,
        address __Traders_rewards
    ) {
        initializer = msg.sender;
        team = msg.sender;
        // TODO: Team rate is 1% and will be increased in the future to 3%
        teamRate = 10; // 300 bps = 1%
        _Loxo = ILoxo(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _NFTstakers_rewards = __NFTstakers_rewards;
        _Traders_rewards = __Traders_rewards;
        _rewards_distributor = IRewardsDistributor(__rewards_distributor);
        active_period = ((block.timestamp + (2 * WEEK)) / WEEK) * WEEK;
        isFirstMint = true;
    }

    function initialize(
        address[] memory claimants,
        uint[] memory amounts,
        uint max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    ) external {
        require(initializer == msg.sender);
        if(max > 0){
            _Loxo.mint(address(this), max);
            _Loxo.approve(address(_ve), type(uint).max);
            for (uint i = 0; i < claimants.length; i++) {
                _ve.create_lock_for(amounts[i], LOCK, claimants[i]);
            }
        }

        initializer = address(0);
        active_period = ((block.timestamp) / WEEK) * WEEK; // allow minter.update_period() to mint new emissions THIS Thursday
        emit PeriodUpdated(active_period);
    }

    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setVoter(address __voter) external {
        require(__voter != address(0));
        require(msg.sender == team, "not team");
        _voter = IVoter(__voter);
    }
    function setNFTstakers(address __NFTstakers) external {
        require(__NFTstakers != address(0));
        require(msg.sender == team, "not team");
        _NFTstakers_rewards = __NFTstakers;
    }
    function setTeamRate(uint _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    function setEmission(uint _emission) external {
        require(msg.sender == team, "not team");
        require(_emission <= PRECISION, "rate too high");
        EMISSION = _emission;
    }


    function setRebase(uint _rebase) external {
        require(msg.sender == team, "not team");
        require(_rebase <= PRECISION, "rate too high");
        REBASEMAX = _rebase;
    }
    function setNFTStaker(uint _NFTStakersReward) external {
        require(msg.sender == team, "not team");
        require(_NFTStakersReward <= PRECISION, "rate too high");
        NFTStakerMAX = _NFTStakersReward;
    }

    function setTradersMAX(uint _TradersReward) external {
        require(msg.sender == team, "not team");
        require(_TradersReward <= PRECISION, "rate too high");
        TradersMAX = _TradersReward;
    }
    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _Loxo.totalSupply() - _ve.supply();
    }

    // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return (weekly * EMISSION) / PRECISION;
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return (circulating_supply() * TAIL_EMISSION) / PRECISION;
    }

    // function calculate_emission() public view returns (uint) {
    //     uint decayFactor = 99 ** ((block.timestamp - active_period) / WEEK); // decay by 1% per week
    //     uint targetEmission = (weekly * EMISSION) / PRECISION;
    //     return Math.min(targetEmission * decayFactor, weekly); // decrease weekly emission
    // }

    // calculate inflation and adjust ve balances accordingly
    function calculate_rebase(uint _weeklyMint) public view returns (uint) {
        // TODO: Rebase is 30%
        uint _veTotal = _ve.supply();
        uint _LoxoTotal = _Loxo.totalSupply();
        
        uint lockedShare = (_veTotal) * PRECISION  / _LoxoTotal;
        if(lockedShare >= REBASEMAX){
            return _weeklyMint * REBASEMAX / PRECISION;
        } else {
            return _weeklyMint * lockedShare / PRECISION;
        }
    }
    function calculate_NFT_Staker_Reward(uint _weeklyMint) public view returns (uint) {
        // TODO: NFT staker reward is 5%
        uint _veTotal = _ve.supply();
        uint _LoxoTotal = _Loxo.totalSupply();
        
        uint lockedShare = (_veTotal) * PRECISION  / _LoxoTotal;
        if(lockedShare >= NFTStakerMAX){
            return _weeklyMint * NFTStakerMAX / PRECISION;
        } else {
            return _weeklyMint * lockedShare / PRECISION;
        }
    }

    function calculate_Traders_Reward(uint _weeklyMint) public view returns (uint) {
        // TODO: NFT staker reward is 4%
        uint _veTotal = _ve.supply();
        uint _LoxoTotal = _Loxo.totalSupply();
        
        uint lockedShare = (_veTotal) * PRECISION  / _LoxoTotal;
        if(lockedShare >= TradersMAX){
            return _weeklyMint * TradersMAX / PRECISION;
        } else {
            return _weeklyMint * lockedShare / PRECISION;
        }
    }
    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + WEEK && initializer == address(0)) { // only trigger if new week
            _period = (block.timestamp / WEEK) * WEEK;
            active_period = _period;

            if(!isFirstMint){

                weekly = weekly_emission();
            } else {
                isFirstMint = false;
            }

            uint _rebase = calculate_rebase(weekly);
            uint _nftStakers = calculate_NFT_Staker_Reward(weekly);
            uint _traders = calculate_Traders_Reward(weekly);
            uint _teamEmissions = weekly * teamRate / PRECISION;
            uint _required = weekly;

            uint _voterAmount = weekly - _rebase - _nftStakers - _traders - _teamEmissions;

            uint _balanceOf = _Loxo.balanceOf(address(this));
            if (_balanceOf < _required) {
                _Loxo.mint(address(this), _required - _balanceOf);
            }

            require(_Loxo.transfer(team, _teamEmissions));
            require(_Loxo.transfer(address(_NFTstakers_rewards), _nftStakers));
            require(_Loxo.transfer(address(_Traders_rewards), _traders));
            require(_Loxo.transfer(address(_rewards_distributor), _rebase));
            _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
            _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

            _Loxo.approve(address(_voter), _voterAmount);
            _voter.notifyRewardAmount(_voterAmount);

            emit PeriodUpdated(active_period);
            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

    function check() external view returns(bool){
        uint _period = active_period;
        return (block.timestamp >= _period + WEEK && initializer == address(0));
    }

    function period() external view returns(uint){
        return(block.timestamp / WEEK) * WEEK;
    }

}
