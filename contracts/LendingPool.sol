// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "./LPToken.sol";
import "./EGoldToken.sol";
import "./EINRToken.sol";
//import "hardhat/console.sol";

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

    address payable wallet = payable(0xa81A0B8f163EAe6E4265964BC2b8975c44119b4B);

    uint256 public thresholdLimitBorrow = 1500 * 10 ** 18;
    uint256 public  thresholdLimitLender = 1000 * 10 ** 18;

    uint public interestRateBorrower = 1000; //10% for borrower
    uint256 public interestRateLender = 800; //8% for lender 
    uint256 public interestRateContract = 200; //2%  application fee commission
    
    //mapping to store the balance of EINR deposited in Lending Pool by particular User.
    mapping(address => uint256)public balanceOfEINR;
    //mapping to store the balance of EGold deposited in Lending Pool by particular User.
    mapping(address => uint256)public balanceOfEGold;
     //mapping to store the balance of EINR borrowed in Lending Pool by particular User.
    mapping(address => uint256)public borrowEINRAmount;
    //mapping to store User Deposited time.
    mapping(address => uint256)public depositStartTime;
    //mapping to store User Borrowed time.
    mapping(address => uint256)public borrowedTime;
    //mapping to check the user has done KYC or not
    mapping(address =>bool) public usersKYCchecks;
    // mapping to store UserRepayment amount for repaying
    mapping(address =>uint256) public userRepayAmount;
    
    /** EVENTS */
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

    modifier onlyAdmin() {
        require(admin == msg.sender, "Not admin");
        _;
    }

    modifier userKycCheck() {
        require(usersKYCchecks[msg.sender] , "Kyc not done");
        _;
    }
    
    // /** @dev In this function the admin can check whether the User has done KYC or not.
    // * @param account pass the user account address.
    // * @param _amount pass the amount of EINR token to be borrowed or deposited.
    // * @return bool whether the KYC is true or false for the particular User account.
    // */
    // function checkKYCForUsers(address account,uint256 _amount)public returns(bool)
    // {
    //     if(_amount >thresholdLimitLender && _amount > thresholdLimitBorrow){
    //         return usersKYCchecks[account]= true;
    //     }else{
    //        return usersKYCchecks[account]= false;
    //     }}
    function setKycForUser(address _user) public onlyAdmin{
        require(!usersKYCchecks[_user], "Kyc already done");
        usersKYCchecks[_user]= true;
    }


   /** @dev In this function the User can deposit their EINR asset in Lending Pool.
    * @param _EINRamount pass the amount of EINR token to deposit in Lending Pool.
    */
    function depositeINRToken(uint256 _EINRamount) external{
        // require(_time == oneMonth ||_time == threeMonths ||_time == sixMonths ||_time == oneYear,
        //     "Deposit Time should be in time limits defined"
        // );
        // require(checkKYCForUsers(msg.sender, _EINRamount), "Need to do Kyc");
        require(_EINRamount > 0 && eINRToken.balanceOf(msg.sender) >= _EINRamount,"You have insufficient EINR");
        balanceOfEINR[msg.sender] += _EINRamount;
        eINRToken.transferFrom(msg.sender, address(this), _EINRamount);
        depositStartTime[msg.sender] = block.timestamp; 
        //durationForLender[msg.sender]= _time;
        totalSupply += _EINRamount;
        emit Deposited(msg.sender, _EINRamount, block.timestamp);
        //get lP token as a proof of receipt 
        lpToken.mint(msg.sender, _EINRamount);
    }

    /** @dev This function calculate the interest earn by the depositor.
    * @return withdrawAmount is the amount with interest earn by depositor.
    */
    function getAmountWithInterest() public view returns(uint256){
       uint256 periodLock = (block.timestamp - depositStartTime[msg.sender])/ 60;
       //uint256 periodLock = durationForLender[msg.sender];
       //console.log(periodLock, "Get the deposit lock time here");
       uint256 interestGain = (((balanceOfEINR[msg.sender]/1e18) * interestRateLender * periodLock ) * 10 / (365 * 24 * 60));
       //console.log(interestGain, "Interest Gain Per min");
       uint256 withdrawAmount = balanceOfEINR[msg.sender] + interestGain;
       //console.log(withdrawAmount, "Amount calculated for Investor with Interest");
       return (withdrawAmount);
    }


    /** @dev In this function the User can withdraw their EINR asset in Lending Pool.
    * @param amountToWithdraw pass the amount of EINR token to deposit in Lending Pool.
    */
    function withDrawEINRToken(uint256 amountToWithdraw) external{
        eINRToken.transfer(msg.sender, amountToWithdraw);
        totalSupply -= amountToWithdraw;
        emit Withdrawed(msg.sender, amountToWithdraw);
        //lp token burnt after withdraw
        lpToken.burn(msg.sender,  balanceOfEINR[msg.sender]);
        balanceOfEINR[msg.sender] = balanceOfEINR[msg.sender] - amountToWithdraw ;    
    }

    /** @dev In this function user get the calculated value of EINR token he can borrow.
    * @param _collateralAmount pass the amount of EGold token as a collateral to be deposited in Lending Pool.
    * @return borrowEinrAmt calculated loan amount based on the collateral deposited.
    */
    function calculatedEINRloan(uint256 _collateralAmount)public view returns(uint256){
        uint256 borrowEinrAmt = _collateralAmount/2 ;
        return(borrowEinrAmt);
    }

    /** @dev In this function the User can borrow  EINR token by depositing Egold token in Lending Pool.
    * @param _collateralAmount pass the amount of EGold token to  deposit in Lending Pool.
    */
    function borrowEINRLoan(uint256 _collateralAmount) external{
        require(eGoldToken.balanceOf(msg.sender) >= _collateralAmount, "you have insufficient EGold token");   
        balanceOfEGold[msg.sender] += _collateralAmount;// track the amount given as collateral
        eGoldToken.transferFrom(msg.sender, address(this), _collateralAmount); //2000 Egold token 
        uint256 EINRamount = _collateralAmount / 2; //loan borrowed is half the price of collateral
        //checkKYCForUsers(msg.sender, EINRamount);
        totalSupply -= EINRamount;
        eINRToken.transfer(msg.sender, EINRamount);  
        borrowedTime[msg.sender] = block.timestamp;
        //durationForBorrower[msg.sender] = _time;
        borrowEINRAmount[msg.sender] += EINRamount;
        // event emitted    
        emit Borrowedloan(msg.sender, EINRamount, block.timestamp);
    }
    
    /** @dev This function calculate the interest to be repaid by the borrower.
    * @return repayAmount is the amount with interest to repay by the borrower.
    */
    function getborrowerRepayAmount()public  returns(uint256){
        uint256 dueTime = (block.timestamp - borrowedTime[msg.sender])/60; 
        //uint256 dueTime = durationForBorrower[msg.sender]; 
        //console.log(dueTime, "Get the loan time here");
        uint256 interestToRepay = (((borrowEINRAmount[msg.sender]/1e18)* interestRateBorrower * dueTime)* 10 /(365 * 24 * 60));// interest for lender
        uint256 repayAmount = borrowEINRAmount[msg.sender] + interestToRepay;//interest added
        //console.log(repayAmount, "Amount to be paid by with Interest to the contract");
        userRepayAmount[msg.sender] += repayAmount;
        return (repayAmount);
    }

    /** @dev In this function the User can repay their EINR asset in Lending Pool.
    * @param finalRepayAmount repay the amount of EINR token with Interest in Lending Pool.
    */
    function repayEINRLoan(uint256 finalRepayAmount)external {
        require(finalRepayAmount > 0 , "User has insufficient Balance to repay the loan");
        uint256 duration = (block.timestamp - borrowedTime[msg.sender])/60; 
        uint256 interestContract =(((borrowEINRAmount[msg.sender]/1e18)* interestRateContract * duration)* 10 /(365 * 24 * 60));
        eINRToken.transfer(admin, interestContract);
        uint256 payback = finalRepayAmount - interestContract;
        //console.log(payback);
        eINRToken.transferFrom(msg.sender ,address(this), payback);
        totalSupply += payback;
        borrowEINRAmount[msg.sender]= 0;//deduct the borrow amount from mapping borrow user mapping
        uint256 repayCollateral = balanceOfEGold[msg.sender];
        eGoldToken.transfer(msg.sender, repayCollateral);
        balanceOfEGold[msg.sender]= 0;
        //event emitted
        emit Repayedloan(msg.sender, finalRepayAmount);
    }

    /** @dev In this function get the Total Supply of EINR in Lending Pool.
    * @return totalSupply gives total amount of EINR stored in Lending .
    */
    function getTotalOfSupplyEINRPool() public view returns(uint256){
        return (totalSupply);
    }

    /** @dev In this function get the Total Supply of EINR locked in Lending Pool.
    * @return einramount gives total amount of EINR stored in Lending .
    */
    function getTotalOfBalanceEINR() public view returns(uint256) {
        uint256 einramount = eINRToken.balanceOf(address(this));
        return (einramount);
    }

    /** @dev In this function get the Total Supply in Lending Pool.
    * @return egoldamount gives total amount of EINR stored in Lending
    */
    function getTotalBalanceEGold() public view returns(uint256){
        uint256 egoldamount = eGoldToken.balanceOf(address(this));
        return (egoldamount);
    }

    /** @dev In this function get User balance of EINR token Deposited in Lending Pool.
    * @param account pass the User  account address.
    * @return baleinr gives User balance of EINR token stored in Lending pool.
    */
    function getOwnerDepositEINRBalance(address account) public view returns(uint256) {
        uint256 baleinr = balanceOfEINR[account];
        return (baleinr);
    }
    
    /** @dev In this function get User balance of EGold token Deposited in Lending Pool.
    * @param account pass the User  account address.
    * @return balegold gives User balance of EGold token stored in Lending pool.
    */
    function getOwnerEGoldBalance(address account) public view returns(uint256){
        uint256 balegold = balanceOfEGold[account];
        return (balegold);
    }

    /** @dev In this function get User balance of EINR token Borrowed from Lending Pool.
    * @param account pass the User  account address.
    * @return baleinborrow gives User balance of EINR token borrowed from Lending pool.
    */
    function getBorrowEINRAmount(address account) public view returns(uint256){
        uint256 baleinborrow = borrowEINRAmount[account];
        return (baleinborrow);
    }

    /** @dev In this function get User balance of LP token minted.
    * @param account pass the User  account address.
    * @return lptokenbal gives User balance of LP token minted in Lending pool.
    */
    function getBalanceOfLPtoken(address account) public view returns(uint256){
        uint256 lptokenbal =  lpToken.balanceOf(account);
        return lptokenbal;
    }
    
    /** @dev In this function get User balance of EINR token to be repaid in Lending Pool.
    * @param account pass the User  account address.
    * @return repaybal gives User repay amount of EINR token with interest borrowed.
    */
    function getUserRepayAmount(address account) public view returns(uint256){
        uint256 repaybal = userRepayAmount[account];
        return repaybal;
    }
}
