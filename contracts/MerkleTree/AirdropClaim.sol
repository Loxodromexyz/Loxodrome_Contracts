// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IVotingEscrow.sol";

contract AirdropClaim is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 lastTimestamp;
        address to;
        uint256 lockedAmount;
        uint256 lockedClaimed;
        uint256 totalAmount;
        uint256 tokenPerSec;
        uint256 claimed;
    }

    bool public init;

    uint256 public startTimestamp;

    uint256 public constant DISTRIBUTION_PERIOD = 180 * 86400; // 6 months
    uint256 public constant LOCK_TIME = 2 * 364 * 86400;

    address public owner;
    address public ve;
    address public merkle;
    IERC20 public token;

    mapping(address => UserInfo) public users;
    mapping(address => bool) public usersFlag;
    mapping(address => bool) public depositors;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyMerkle() {
        require(msg.sender == merkle, "not owner");
        _;
    }

    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    constructor(address _token, address _ve) {
        owner = msg.sender;
        token = IERC20(_token);
        ve = _ve;
    }

    function deposit(uint256 amount) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(amount);
    }

    function withdraw(uint256 amount, address _token, address _to) external {
        require(depositors[msg.sender] == true || msg.sender == owner);
        IERC20(_token).safeTransfer(_to, amount);
        emit Withdraw(amount);
    }

    /// @notice set user infromation for the claim
    /// @param _who is claiming
    /// @param _to who's getting the token
    /// @param _amount total amount to claim
    /// @param _veAmount total veLoxo amount to claim
    function setUserInfoAndClaim(
        address _who,
        address _to,
        uint256 _amount,
        uint256 _veAmount
    ) external onlyMerkle nonReentrant returns (bool status) {
        require(_who != address(0), "addr 0");
        require(_to != address(0), "addr 0");
        require(_amount > 0, "amnt 0");
        require(_veAmount >= 0, "veLoxo amount lte 0");
        require(usersFlag[_who] == false, "!flag");
        require(init, "not init");

        uint256 lastTimestamp = block.timestamp;
        require(lastTimestamp > startTimestamp, 'airdrop no start');
        uint256 tokenPerSec = _amount / DISTRIBUTION_PERIOD;
        uint256 claimed = (lastTimestamp - startTimestamp) * tokenPerSec;

        UserInfo memory _userInfo = UserInfo({
            lastTimestamp: lastTimestamp,
            to: _to,
            totalAmount: _amount,
            tokenPerSec: tokenPerSec,
            claimed: claimed,
            lockedAmount: _veAmount,
            lockedClaimed: 0
        });
        users[_who] = _userInfo;
        usersFlag[_who] = true;

        // transfer
        token.safeTransfer(_to, claimed);

        status = true;
    }

    /// @notice set user infromation for the claim
    /// @param _who is claiming
    /// @param _to who's getting the token
    /// @param _amount total amount to claim
    /// @param _veAmount total veLoxo amount to claim
    function setUserInfoAndClaimVe(
        address _who,
        address _to,
        uint256 _amount,
        uint256 _veAmount
    ) external onlyMerkle nonReentrant returns (bool status) {
        require(_who != address(0), "addr 0");
        require(_to != address(0), "addr 0");
        require(_amount > 0, "amnt 0");
        require(_veAmount >= 0, "veLoxo amount lte 0");
        require(usersFlag[_who] == false, "!flag");
        require(init, "not init");

        uint256 lastTimestamp = block.timestamp;
        require(lastTimestamp > startTimestamp, 'airdrop no start');
        uint256 tokenPerSec = _amount / DISTRIBUTION_PERIOD;

        UserInfo memory _userInfo = UserInfo({
            lastTimestamp: startTimestamp,
            to: _to,
            totalAmount: _amount,
            tokenPerSec: tokenPerSec,
            claimed: 0,
            lockedAmount: _veAmount,
            lockedClaimed: _veAmount
        });
        users[_who] = _userInfo;
        usersFlag[_who] = true;
        token.safeTransfer(_to, _veAmount);
        token.approve(ve, 0);
        token.approve(ve, _veAmount);
        IVotingEscrow(ve).create_lock_for(_veAmount, LOCK_TIME, _to);
        status = true;
    }

    function claim() external nonReentrant {
        // check user exists
        require(usersFlag[msg.sender]);

        // load info
        UserInfo memory _user = users[msg.sender];

        // check lastTimestamp
        require(
            _user.lastTimestamp <= startTimestamp + DISTRIBUTION_PERIOD,
            "time: claimed all"
        );
        require(_user.claimed <= _user.totalAmount, "amnt: claimed all");

        // save _to
        address _to = _user.to;

        // check if timestamp is > than the vesting period timestamp
        // if true then save timestamp as last possible timestamp
        uint256 _timestamp = block.timestamp;
        if (_timestamp > startTimestamp + DISTRIBUTION_PERIOD) {
            _timestamp = startTimestamp + DISTRIBUTION_PERIOD;
        }

        // find how many token
        uint256 _dT = _timestamp - _user.lastTimestamp;
        require(_dT > 0);
        uint256 _claimable = _dT * _user.tokenPerSec;

        // update and check math
        _user.lastTimestamp = _timestamp;
        _user.claimed += _claimable;
        require(_user.claimed <= _user.totalAmount, "claimed > totAmnt");
        users[msg.sender] = _user;

        // transfer
        token.safeTransfer(_to, _claimable);
    }

    function claimVe() external nonReentrant {
        // check user exists
        require(usersFlag[msg.sender]);

        // load info
        UserInfo memory user = users[msg.sender];

        require(user.lockedClaimed < user.lockedAmount, 'claimed all');

        uint256 claimable_ = user.lockedAmount - user.lockedClaimed;
        user.lockedClaimed += claimable_;
        require(user.lockedClaimed <= user.lockedAmount, 'claimed > total');
        users[msg.sender] = user;
        token.safeTransfer(user.to, claimable_);
        token.approve(ve, 0);
        token.approve(ve, claimable_);
        IVotingEscrow(ve).create_lock_for(claimable_, LOCK_TIME, user.to);
    }

    function claimable(address user) public view returns (uint _claimable) {
        // check user exists
        require(usersFlag[user]);
        // load info
        UserInfo memory _user = users[user];

        // check lastTimestamp
        require(
            _user.lastTimestamp <= startTimestamp + DISTRIBUTION_PERIOD,
            "time: claimed all"
        );
        require(_user.claimed <= _user.totalAmount, "amnt: claimed all");

        // check if timestamp is > than the vesting period timestamp
        // if true then save timestamp as last possible timestamp
        uint256 _timestamp = block.timestamp;
        if (_timestamp > startTimestamp + DISTRIBUTION_PERIOD) {
            _timestamp = startTimestamp + DISTRIBUTION_PERIOD;
        }

        // find how many token
        uint256 _dT = _timestamp - _user.lastTimestamp;
        require(_dT > 0);
        _claimable = _dT * _user.tokenPerSec;
    }

    function claimableVe(address account) public view returns (uint _claimable) {
        // check user exists
        require(usersFlag[account]);
        // load info
        UserInfo memory user = users[account];
        _claimable = user.lockedAmount - user.lockedClaimed;
    }

    /* 
        OWNER FUNCTIONS
    */

    function setDepositor(address depositor) external onlyOwner {
        require(depositors[depositor] == false);
        depositors[depositor] = true;
    }

    function setMerkleTreeContract(address _merkle) external onlyOwner {
        require(_merkle != address(0));
        merkle = _merkle;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

    function initialize(uint256 startTimestamp_) external onlyOwner {
        require(init == false);
        init = true;
        startTimestamp = startTimestamp_; //block.timestamp;
    }
}
