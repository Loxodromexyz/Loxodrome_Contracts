// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IMinter.sol";
import "./interfaces/IVoter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./APIHelper/PairAPIV2.sol";

contract EpochController is OwnableUpgradeable  {

    address public automationRegistry;

    address public minter;
    address public voter;
    address public pairAPIAddress;
    uint256 public totalPairs;

    constructor() {}

    function initialize(address _minter, address _voter, address _automationRegistry, address _pairAPIAddress) public initializer {
        __Ownable_init();
        minter = _minter;
        voter = _voter;
        automationRegistry = _automationRegistry;
        pairAPIAddress = _pairAPIAddress;
        totalPairs = 4;
    }


    function checkUpkeep() public view  returns (bool upkeepNeeded) {
        upkeepNeeded = IMinter(minter).check();
    }
    function performUpkeep() external  {
        require(msg.sender == automationRegistry || msg.sender == owner(), "cannot execute");
        bool upkeepNeeded = checkUpkeep();
        require(upkeepNeeded, "condition not met");
        
        IVoter(voter).distributeAll();
        collectFeesAndDistribute();
    }

    function collectFeesAndDistribute() public {
        PairAPI pairAPI = PairAPI(pairAPIAddress);
        PairAPI.pairInfo[] memory pairs = pairAPI.getAllPair(address(0), totalPairs, 0);
        address[] memory validGauges = new address[](pairs.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < pairs.length; i++) {
            if (pairs[i].gauge != address(0)) { // Check if the gauge address is not zero
                validGauges[validCount] = pairs[i].gauge;
                validCount++;
            }
        }

        // Create a new array with the correct length of valid gauges
        address[] memory gauges = new address[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            gauges[i] = validGauges[i];
        }

        IVoter(voter).distributeFees(gauges);
    }

    function setTotalPairs(uint256 _totalPairs) external onlyOwner {
        totalPairs = _totalPairs;
    }
    function setAutomationRegistry(address _automationRegistry) external onlyOwner {
        require(_automationRegistry != address(0));
        automationRegistry = _automationRegistry;
    }
    function setPairAPIAddress(address _pairAPIAddress) external onlyOwner {
        pairAPIAddress = _pairAPIAddress;
    }
    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = _voter;
    }

    function setMinter(address _minter ) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }



}