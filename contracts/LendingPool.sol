// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "./LPToken.sol";
import "./EGoldToken.sol";
import "./EINRToken.sol";
//import "hardhat/console.sol";


error TransferFailed();

contract LendingPool{
    //address of owner of this contract
    address public admin;

    uint256 public timePeriodLock;
    //instance of 
    LPToken public lpToken;
    //instance of EGoldToken
    EGoldToken public eGoldToken;
    //instance of EINRToken
    EINRToken public eINRToken;
    //total supply of EINR in lending pool
    uint256 public totalSupply;

    bool kYCcheck;

    uint256 thresholdAmountBorrow = 1500;
    uint256 thresholdAmountLender = 1000;

    uint public interestRateBorrower = 10;//10% for borrower
    uint256 public interestRateLender = 8;//8% for lender 
    uint256 public interestRateOwner = 2;//2% 

   
    mapping(address => uint256)public balanceOfEINR;

    mapping(address => uint256)public balanceOfEGold;

    mapping(address => uint256)public borrowEINRAmount;

    mapping(address => uint256)public depositedTime;

    mapping(address => uint256)public borrowedTime;
    
    event Deposited(address indexed account, uint256 amount);
    event Withdrawed(address indexed account, uint256 amount);
    event Borrowedloan(address indexed account,uint256 amount);
    event Repayedloan(address indexed account, uint256 amount);

    constructor(address _eINRToken, address _eGoldToken, address _lpToken) {
        admin = msg.sender;
        eINRToken = EINRToken(_eINRToken);
        eGoldToken = EGoldToken(_eGoldToken);
        lpToken = LPToken(_lpToken);       
    }

    function depositeINRToken(uint256 _EINRamount) external{
        depositedTime[msg.sender] = block.timestamp; 
        require(_EINRamount > 0 && eINRToken.balanceOf(msg.sender) >= _EINRamount,"You have insufficient EINR");
        balanceOfEINR[msg.sender] += _EINRamount;
        totalSupply += _EINRamount;
        bool success = eINRToken.transferFrom(msg.sender, address(this), _EINRamount);
        if(!success){
            revert TransferFailed();
        } 
        emit Deposited(msg.sender, _EINRamount);
        //get lP token as a proof of receipt 
        lpToken.mint(msg.sender,100000);

    }

    //with 8% interest given to investor
    function withDrawEINRToken(uint256 _EINRamount) external{ 
        timePeriodLock = (block.timestamp - depositedTime[msg.sender])/ 60;
        uint256 interestGain = ((_EINRamount * interestRateLender * timePeriodLock )/ (365 * 24 * 60));
        console.log(interestGain, "Interest Gain Per min");
        require(_EINRamount > 0 && balanceOfEINR[msg.sender] == _EINRamount , "Amount should not be 0");
        balanceOfEINR[msg.sender] += interestGain;
        uint256 withdrawEINR = balanceOfEINR[msg.sender];
        console.log(balanceOfEINR[msg.sender], "updated balance -----");
        balanceOfEINR[msg.sender] -= withdrawEINR;
        totalSupply -= _EINRamount;
        bool success = eINRToken.transfer(msg.sender, withdrawEINR);
        if(!success){
            revert TransferFailed();
        }
        emit Withdrawed(msg.sender, withdrawEINR);
        //lp token burnt after withdraw
        lpToken.burn(msg.sender, 100000);
        
    }
    
    function borrowEINRLoan(uint256 _collateralAmount) external{
        borrowedTime[msg.sender] = block.timestamp;
        require(eGoldToken.balanceOf(msg.sender) >= _collateralAmount, "you have insufficient EGold token");
        balanceOfEGold[msg.sender] += _collateralAmount;
        eGoldToken.transferFrom(msg.sender, address(this), _collateralAmount); 
        uint256 EINRamount = _collateralAmount / 2; //loan borrowed is half the price of collateral
        totalSupply -= EINRamount;
        eINRToken.mint(msg.sender, EINRamount);  

        borrowEINRAmount[msg.sender] = EINRamount;
        // event emitted    
        emit Borrowedloan(msg.sender, EINRamount);

    }

    //with 10% interest to be paid by borrower 
    function repayEINRLoan(uint256 _EINRamount)external{
        uint256 dueTime = (block.timestamp - borrowedTime[msg.sender])/60;
        uint256 interestToPay = (_EINRamount * interestRateBorrower * dueTime)/(365 * 24 * 60);
        console.log(interestToPay, "Calculated Interest to be paid per min"); 
        require(eINRToken.balanceOf(msg.sender) >= _EINRamount,"you have insufficient balance");
        uint256 repayAmount = borrowEINRAmount[msg.sender] + interestToPay;//interest added
        console.log(repayAmount, "Amount to be paid by with Interest to the contract");
        borrowEINRAmount[msg.sender] -= _EINRamount;//deduct the borrow amount from mapping
        totalSupply += repayAmount ;
        eINRToken.transfer(address(this), repayAmount);
        uint256 repayCollateral = balanceOfEGold[msg.sender];
        eGoldToken.transfer(msg.sender, repayCollateral);
        //event emitted
        emit Repayedloan(msg.sender, repayAmount);
    }
    

    function getBalanceEINR() public view returns(uint256){
        return(eINRToken.balanceOf(address(this)));
    }
    
    function calculateContractFee()external view returns(uint256){
        
    }
}
