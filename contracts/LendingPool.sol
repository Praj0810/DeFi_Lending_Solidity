// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "./LPToken.sol";
import "./EGoldToken.sol";
import "./EINRToken.sol";
//import "hardhat/console.sol";


error TransferFailed();

contract LendingPool{
    //address of owner of this contract
    address payable admin;
    //instance of Lptoken
    LPToken public lpToken;
    //instance of EGoldToken
    EGoldToken public eGoldToken;
    //instance of EINRToken
    EINRToken public eINRToken;
    //total supply of EINR in lending pool
    uint256 public totalSupply;

    

    uint256 thresholdLimitBorrow = 1500 * 10 ** 18;
    uint256 thresholdLimitLender = 1000 * 10 ** 18;

    uint public interestRateBorrower = 1000; //10% for borrower
    uint256 public interestRateLender = 800; //8% for lender 
    uint256 public interestRateCommission = 200; //2%  application fee commission

   
    mapping(address => uint256)public balanceOfEINR;

    mapping(address => uint256)public balanceOfEGold;

    mapping(address => uint256)public borrowEINRAmount;

    mapping(address => uint256)public depositStartTime;

    mapping(address => uint256)public borrowedTime;

    mapping(address =>bool) public usersKYCchecks;
    
    event Deposited(address indexed account, uint256 eINRamount, uint256 startDepositTime);
    event Withdrawed(address indexed account, uint256 amount);
    event Borrowedloan(address indexed account,uint256 amount, uint256 startBorrowTime);
    event Repayedloan(address indexed account, uint256 amount);

    constructor(address _eINRToken, address _eGoldToken, address _lpToken) {
        admin = payable(msg.sender);
        eINRToken = EINRToken(_eINRToken);
        eGoldToken = EGoldToken(_eGoldToken);
        lpToken = LPToken(_lpToken);       
    }

    function checkKYCForUsers(address account,uint256 _amount)public 
    {
        if(_amount >thresholdLimitLender && _amount > thresholdLimitBorrow){
            usersKYCchecks[account]= true;
        }else{
            usersKYCchecks[account]= false;
        }
    }

    function depositeINRToken(uint256 _EINRamount) external{
        checkKYCForUsers(msg.sender, _EINRamount);
        require(_EINRamount > 0 && eINRToken.balanceOf(msg.sender) >= _EINRamount,"You have insufficient EINR");
        depositStartTime[msg.sender] = block.timestamp; 
        balanceOfEINR[msg.sender] += _EINRamount;
        totalSupply += _EINRamount;
        
        eINRToken.transferFrom(msg.sender, address(this), _EINRamount);
        
        emit Deposited(msg.sender, _EINRamount, block.timestamp);
        //get lP token as a proof of receipt 
        lpToken.mint(msg.sender,1000 * 1e18);
    }

    function getAmountWithInterest(uint256 _EINRamount)public view returns(uint256){
       require(_EINRamount > 0 && balanceOfEINR[msg.sender] == _EINRamount , "Amount should not be 0");
       uint256 periodLock = (block.timestamp - depositStartTime[msg.sender])/ 60;
        //console.log(periodLock, "Get the deposit lock time here");
       uint256 interestGain = (((_EINRamount/1e18) * interestRateLender * periodLock )*1e5/ (365 * 24 * 60));
      // console.log(interestGain, "Interest Gain Per min");
       uint256 withdrawAmount = balanceOfEINR[msg.sender] + interestGain;
       //console.log(withdrawAmount, "Amount calculated for Investor with Interest");
       return (withdrawAmount);
    }


    //with 8% interest given to investor
    function withDrawEINRToken(uint256 amountToWithdraw) external{
        balanceOfEINR[msg.sender] = 0;
        totalSupply -= amountToWithdraw;
        eINRToken.transfer(msg.sender, amountToWithdraw);
        emit Withdrawed(msg.sender, amountToWithdraw);
        //lp token burnt after withdraw
        lpToken.burn(msg.sender, 1000 * 1e18);
        
    }
    
    function borrowEINRLoan(uint256 _collateralAmount) external{
        require(eGoldToken.balanceOf(msg.sender) >= _collateralAmount, "you have insufficient EGold token");
        borrowedTime[msg.sender] = block.timestamp;
        balanceOfEGold[msg.sender] += _collateralAmount;// track the amount given as collateral
        eGoldToken.transferFrom(msg.sender, address(this), _collateralAmount); //2000 Egold token 
        uint256 EINRamount = _collateralAmount / 2; //loan borrowed is half the price of collateral
        checkKYCForUsers(msg.sender, EINRamount);
        totalSupply -= EINRamount;
        eINRToken.transfer(msg.sender, EINRamount);  

        borrowEINRAmount[msg.sender] += EINRamount;
        // event emitted    
        emit Borrowedloan(msg.sender, EINRamount, block.timestamp);

    }

    // function interestCalculation(uint256 _EINRamount) public view {
    //     uint256 interestY = (((_EINRamount/10**18)* interestRateLender * 1)* 1e3 /(365 * 24 * 60));// interest for lender
    //     console.log(interestY, "8 % interest calculated for Lenders");
    //     uint256 interestX = (((_EINRamount/10**18) * interestRateCommission * 1)* 1e3 /(365 * 24 * 60 ));
    //     console.log(interestX, " 2% interest calculated for contract fee");
    //     //admin.transfer(interestX);//response
    //     uint256 totalinterest = interestY + interestX;
    //     console.log(totalinterest, "check 10% here");
    // }


    function getborrowerRepayAmount(uint256 _EINRamount)public view returns(uint256){
        require(eINRToken.balanceOf(msg.sender) > _EINRamount,"you have insufficient balance");
        uint256 dueTime = (block.timestamp - borrowedTime[msg.sender])/60; 
        //console.log(dueTime, "Get the loan time here");
        uint256 interestToRepay = (((_EINRamount/1e18)* interestRateBorrower * dueTime)* 1e5 /(365 * 24 * 60));// interest for lender
        uint256 repayAmount = borrowEINRAmount[msg.sender] + interestToRepay;//interest added
        //console.log(repayAmount, "Amount to be paid by with Interest to the contract");
        return (repayAmount);
    }
    
    function repayEINRLoan(uint256 repayAmount)external {
        //require(amountToRepay == totalAmountPray , "User has insufficient Balance to repay the loan");
        borrowEINRAmount[msg.sender]= 0;//deduct the borrow amount from mapping borrow user mapping
        totalSupply += repayAmount ;
        eINRToken.transferFrom(msg.sender ,address(this), repayAmount);
        uint256 repayCollateral = balanceOfEGold[msg.sender];
        eGoldToken.transfer(msg.sender, repayCollateral);
        balanceOfEGold[msg.sender]= 0;
        //event emitted
        emit Repayedloan(msg.sender, repayAmount);
    }
    

    function getBalanceEINR() public view returns(uint256){
        return(eINRToken.balanceOf(address(this)));
    }
}
