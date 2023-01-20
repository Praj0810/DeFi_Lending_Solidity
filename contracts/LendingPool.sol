// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "./LPToken.sol";
import "./EGoldToken.sol";
import "./EINRToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error TransferFailed();

contract LendingPool{

    using SafeMath for uint256;
    //address of owner of this contract
    address public admin;

    uint256 public dueDate;
    //instance of LPToken
    LPToken public lpToken;
    //instance of EGoldToken
    EGoldToken public eGoldToken;
    //instance of EINRToken
    EINRToken public eINRToken;
    //total supply of EINR in lending pool
    uint256 public totalSupply;

    uint256 public EGoldTokenPrice;

    bool kYCcheck;

    uint256 thresholdAmountBorrow = 1500;
    uint256 thresholdAmountLender = 1000;

    uint256 public interestRateBorrower = 1000;//10% for borrower
    uint256 public interestRateLender = 800;//8% for lender 
    uint256 public interestRateOwner = 200;//2% 

   
    mapping(address => uint256)public balanceOfEINR;

    mapping(address => uint256)public balanceOfEGold;

    mapping(address => uint256)public borrowEINRAmount;
    
    event Deposited(address indexed account, uint256 amount);
    event WithDrawed(address indexed account, uint256 amount);
    event Borrowedloan(address indexed account,uint256 amount);
    event Repayedloan(address indexed account, uint256 amount);

    constructor(address _eINRToken, address _eGoldToken, address _lpToken, uint256 loanDuration) {
        admin = msg.sender;
        eINRToken = EINRToken(_eINRToken);
        eGoldToken = EGoldToken(_eGoldToken);
        lpToken = LPToken(_lpToken);
        dueDate = block.timestamp + loanDuration;
        
        
    }
    // function calculateInterest(uint256 _amount, uint256 _rate, uint256 _timePeriod)public {
    //     uint256 interest = (_amount * 1000)/1e18;

    // }
    function setEGoldPriceEINR(uint256 _price) public {
        EGoldTokenPrice = _price;
     }

    function depositeINRToken(uint256 _EINRamount) external{
        if(_EINRamount > thresholdAmountLender){
            kYCcheck = true;    
            require(eINRToken.balanceOf(msg.sender) >= _EINRamount,"You have insufficient EINR");
            balanceOfEINR[msg.sender] = balanceOfEINR[msg.sender].add(_EINRamount);
            totalSupply = totalSupply.add( _EINRamount);
            bool success = eINRToken.transferFrom(msg.sender, address(this),_EINRamount);
            if(!success){
                revert TransferFailed();
            } 
            emit Deposited(msg.sender, _EINRamount);
            //get lP token as a proof of receipt 
            lpToken.mint(msg.sender, 10);
        }

    }
    //with 8% interest given to investor
    function withDrawEINRToken(uint256 _EINRamount) external{ 
        require(_EINRamount > 0, "Amount should not be 0");
        uint256 withdrawEINR = balanceOfEINR[msg.sender].add(interestRateLender); 
        balanceOfEINR[msg.sender]= balanceOfEINR[msg.sender].sub(_EINRamount);
        totalSupply = totalSupply.sub(_EINRamount);
        bool success = eINRToken.transfer(msg.sender, withdrawEINR);
        if(!success){
            revert TransferFailed();
        }
        emit WithDrawed(msg.sender, withdrawEINR);
        //lp token burnt after withdraw
        lpToken.burn(msg.sender, 10);
        
    }
    
    function borrowEINRLoan(uint256 _collateralAmount) external{
        require(eGoldToken.balanceOf(msg.sender) >= _collateralAmount, "you have insufficient EGold token");
        balanceOfEGold[msg.sender] = balanceOfEGold[msg.sender].add(_collateralAmount);
        eGoldToken.transferFrom(msg.sender,address(this),_collateralAmount); 
        uint256 borrowAmount = (_collateralAmount.div(1e18)).mul(EGoldTokenPrice);
        if(borrowAmount > thresholdAmountBorrow){
            kYCcheck = true;
        }
        totalSupply = totalSupply.sub(borrowAmount);
        eINRToken.transfer(msg.sender, borrowAmount);  

        borrowEINRAmount[msg.sender] = borrowAmount;
        // event emitted    
        emit Borrowedloan(msg.sender, borrowAmount);

    }

    //with 10% interest to be paid by borrower 
    function repayEINRLoan(uint256 _EINRAmount)external{
        require(eINRToken.balanceOf(msg.sender) >= _EINRAmount,"you have insufficient balance");
        uint256 repayAmount = borrowEINRAmount[msg.sender].add(interestRateBorrower);
        borrowEINRAmount[msg.sender] =  borrowEINRAmount[msg.sender].sub(_EINRAmount);
        totalSupply = totalSupply.add(repayAmount);
        eINRToken.transferFrom(msg.sender,address(this), repayAmount);
        uint256 repayCollateral = balanceOfEGold[msg.sender];
        eGoldToken.transfer(msg.sender, repayCollateral);
        //event emitted
        emit Repayedloan(msg.sender, repayAmount);
    }

    function getBalanceEINR() public view returns(uint256){
        return(eINRToken.balanceOf(address(this)));
    }
 
}
