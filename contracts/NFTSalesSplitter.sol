// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/IERC20.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IRoyalties{
    function deposit(uint256 amount) external;
}
interface IWIOTX{
     function deposit() external payable ;
}

interface IStakingNFTConverter {
    function claimFees() external;
    function swap() external;
}

// The base pair of pools, either stable or volatile
contract NFTSalesSplitter is OwnableUpgradeable  {

    uint256 constant public PRECISION = 1000;
    uint256 constant public WEEK = 86400 * 2;
    uint256 public converterFee;
    uint256 public royaltiesFee;
    

    address public wIOTX;
    
    address public stakingConverter;
    address public royalties;


    mapping(address => bool) public splitter;


    event Split(uint256 indexed timestamp, uint256 toStake, uint256 toRoyalties);
    
    modifier onlyAllowed() {
        require(msg.sender == owner() || splitter[msg.sender]);
        _;
    }

    constructor() {}

    function initialize() initializer  public {
        __Ownable_init();
        wIOTX = 0x87B873224EaD2a8cbBB7CfB39b18a795e7DA8CC7;
        stakingConverter = address(0xDC259a3ab993d29c9584e5AA85463E00117b88A4);
        royalties = address(0x5b6af9BB85c510411BaBD6EacC9c72892C3B894b);
        converterFee = 333;
        royaltiesFee = 667;

    }

    function swapWIOTXToIOTX() public onlyAllowed {
        _swapWIOTXToIOTX();
    }

    function _swapWIOTXToIOTX() internal {
        if(address(this).balance > 0){
            IWIOTX(wIOTX).deposit{value: address(this).balance}();
        }
    }

    function split() public onlyAllowed {
        
        // convert IOTX to wIOTX, easier to handle
        _swapWIOTXToIOTX();

        uint256 balance = balanceOf();
        uint256 stakingAmount = 0;
        uint256 royaltiesAmount = 0;
        uint256 timestamp = block.timestamp / WEEK * WEEK;
        if(balance > 1000){
            if(stakingConverter != address(0)){
                stakingAmount = balance * converterFee / PRECISION;
                IERC20(wIOTX).transfer(stakingConverter, stakingAmount);
                IStakingNFTConverter(stakingConverter).claimFees();
                IStakingNFTConverter(stakingConverter).swap();
            }

            if(royalties != address(0)){
                royaltiesAmount = balance * royaltiesFee / PRECISION;
                //check we have all, else send balanceOf
                if(balanceOf() < royaltiesAmount){
                    royaltiesAmount = balanceOf();
                }
                IERC20(wIOTX).approve(royalties, 0);
                IERC20(wIOTX).approve(royalties, royaltiesAmount);
                IRoyalties(royalties).deposit(royaltiesAmount);
            }   
            emit Split(timestamp, stakingAmount, royaltiesAmount);
        } else {
            emit Split(timestamp, 0, 0);
        }    

    }

    function balanceOf() public view returns(uint){
        return IERC20(wIOTX).balanceOf(address(this));
    }

    function setConverter(address _converter) external onlyOwner {
        require(_converter != address(0));
        stakingConverter = _converter;
    }

    function setRoyalties(address _royal) external onlyOwner {
        require(_royal != address(0));
        royalties = _royal;
    }

    function setSplitter(address _splitter, bool _what) external onlyOwner {
        splitter[_splitter] = _what;
    }

    
    ///@notice in case token get stuck.
    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }

    function setFees(uint256 _amountToStaking, uint256 _amountToRoyalties ) external onlyOwner {
        require(converterFee + royaltiesFee <= PRECISION, 'too many');
        converterFee = _amountToStaking;
        royaltiesFee = _amountToRoyalties;
    }

    receive() external payable {}

}