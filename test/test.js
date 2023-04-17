const LendingPool = artifacts.require("LendingPool");
const LPToken = artifacts.require("LPToken");
const EGoldToken = artifacts.require("EGoldToken");
const EINRToken = artifacts.require("EINRToken");
const { all } = require('bluebird');
const web3 = require('web3');

contract("DeFi Lending App", (accounts) => {
  let eGoldToken, eInrToken, lpToken, lendingPool, eINRAmount, eGoldAmount;

  before(async () => {
    wallet = accounts[4];
    eGoldToken = await EGoldToken.deployed();
    console.log("EGoldToken", eGoldToken.address);
    lpToken = await LPToken.deployed();
    console.log("LPToken", lpToken.address);
    eInrToken = await EINRToken.deployed();
    console.log("EINRToken", eInrToken.address);
    lendingPool = await LendingPool.deployed(eInrToken.address, eGoldToken.address,lpToken.address);
    console.log("LendingPool", lendingPool.address);   
  });

  it("All contract should get deployed properly", async () => {
    assert(eGoldToken.address !== "");
    assert(lpToken.address !== "");
    assert(eInrToken.address !== "");
    assert(lendingPool.address !== "");
  });

  it("Lending other contract address", async () => {
    let _egold = await lendingPool.eGoldToken();
    let _einr = await lendingPool.eINRToken();
    let _lp = await lendingPool.lpToken();  
    assert.equal(_egold, eGoldToken.address);
    assert.equal(_einr, eInrToken.address);
    assert.equal(_lp, lpToken.address);
  });
 
  it("10000 EINR Token minted to Account[0]", async () => {
    // balanceAcc0B4 ,balanceAcc1B4,balanceAcc2B4 = "Balance of Account 0 , 1 , 2 before minting tokens "
    let balanceAcc0B4 = await eInrToken.balanceOf(accounts[0]);
    let balanceAcc1B4 = await eInrToken.balanceOf(accounts[1]);
    let balanceAcc2B4 = await eInrToken.balanceOf(accounts[2]);
    //transfer of EINR token in Account1 and Account2 
    await eInrToken.transfer(accounts[1], web3.utils.toWei("2000", "ether"))
    await eInrToken.transfer(accounts[2], web3.utils.toWei("2000", "ether"))
    let balanceAcc0A = await eInrToken.balanceOf(accounts[0]);
    let balanceAcc1A = await eInrToken.balanceOf(accounts[1]);
    let balanceAcc2A = await eInrToken.balanceOf(accounts[2]);
    assert.notEqual(web3.utils.fromWei(balanceAcc0B4, "ether") , web3.utils.fromWei(balanceAcc0A, "ether"));
    assert.notEqual(web3.utils.fromWei(balanceAcc1B4, "ether") , web3.utils.fromWei(balanceAcc1A, "ether"));
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4, "ether") , web3.utils.fromWei(balanceAcc2A, "ether"));
  });

  it("50000 EGold Token minted to Account[0]", async () => {
    // balanceAcc0B4 ,balanceAcc1B4,balanceAcc2B4 = "Balance of Account 0 , 1 , 2 before minting tokens "
    let balanceAcc0B4 = await eGoldToken.balanceOf(accounts[0]);
    let balanceAcc2B4 = await eGoldToken.balanceOf(accounts[2]);
    //transfer of EINR token in Account2:
    await eGoldToken.transfer(accounts[2], web3.utils.toWei("4000", "ether"))
    let balanceAcc0A = await eGoldToken.balanceOf(accounts[0]);
    let balanceAcc2A = await eGoldToken.balanceOf(accounts[2]);
    assert.notEqual(web3.utils.fromWei(balanceAcc0B4, "ether") , web3.utils.fromWei(balanceAcc0A, "ether"));
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4, "ether") , web3.utils.fromWei(balanceAcc2A, "ether"));
  });
  

  it("User can Deposit in Lending Pool", async () => {
    //console.log(account[1].address);
    let balanceAcc0B4 = await eInrToken.balanceOf(accounts[0]);
    let balanceAcc1B4 = await eInrToken.balanceOf(accounts[1]);
    let approvalFromAcc0 = await eInrToken.approve(lendingPool.address, web3.utils.toWei("1000", "ether"),{from:accounts[0]})
    let approvalFromAcc1 = await eInrToken.approve(lendingPool.address, web3.utils.toWei("1000", "ether"),{from:accounts[1]})
    let TotalSupplyB4 = await lendingPool.totalSupply();
    let lendFromAcc0 = await lendingPool.depositeINRToken(web3.utils.toWei("1000", "ether"), {from: accounts[0]});
    let lend = await lendingPool.depositeINRToken(web3.utils.toWei("1000", "ether"), {from: accounts[1]});
    let balanceAcc0After = await eInrToken.balanceOf(accounts[0]);   
    let balanceAcc1After = await eInrToken.balanceOf(accounts[1]);  
    let TotalSupplyA = await lendingPool.totalSupply();
    assert.notEqual(web3.utils.fromWei(balanceAcc0B4, "ether") , web3.utils.fromWei(balanceAcc0After, "ether"));
    assert.notEqual(web3.utils.fromWei(balanceAcc1B4, "ether") , web3.utils.fromWei(balanceAcc1After, "ether"));
    assert.notEqual(web3.utils.fromWei(TotalSupplyB4, "ether") , web3.utils.fromWei(TotalSupplyA, "ether"));
});


  it("User can Borrow Asset from Lending Pool", async () => {
    let balanceAcc2B4egold = await eGoldToken.balanceOf(accounts[2]);
    let balanceAcc2B4einr = await eInrToken.balanceOf(accounts[2]);
    let check = await eGoldToken.approve(lendingPool.address, web3.utils.toWei("2000", "ether"),{from:accounts[2]})
    let TotalSupplyB4 = await lendingPool.totalSupply();
    let borrow = await lendingPool.borrowEINRLoan(web3.utils.toWei("2000", "ether"), {from: accounts[2]});
    let balanceAcc2Afteregold = await eGoldToken.balanceOf(accounts[2]);
    let balanceAcc2Aeinr = await eInrToken.balanceOf(accounts[2])
    let TotalSupplyA = await lendingPool.totalSupply();
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4egold, "ether") , web3.utils.fromWei(balanceAcc2Afteregold, "ether"));
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4einr, "ether") , web3.utils.fromWei(balanceAcc2Aeinr, "ether"));
    assert.notEqual(web3.utils.fromWei(TotalSupplyB4, "ether") , web3.utils.fromWei(TotalSupplyA, "ether"));
  })

  it("User can repay the Asset to the Lending Pool with Interest", async() =>{
    let balanceAcc2B4egold = await eGoldToken.balanceOf(accounts[2]);
    let TotalSupplyB4 = await lendingPool.totalSupply();
    let balanceAcc2B4einr = await eInrToken.balanceOf(accounts[2]);
    let AmountRepayInterest = await lendingPool.getborrowerRepayAmount.call({from:accounts[2]});
    console.log(AmountRepayInterest.toString(), "Interest calculated");
    let check = await eInrToken.approve(lendingPool.address, web3.utils.toWei("1000", "ether"),{from:accounts[2]})
    let repay = await lendingPool.repayEINRLoan(String(AmountRepayInterest), {from: accounts[2]});
    let balanceOfContract = eInrToken.balanceOf(wallet);
    console.log(balanceOfContract);
    let balanceAcc2AfterEGold = await eGoldToken.balanceOf(accounts[2])
    let balanceAcc2Aeinr = await eInrToken.balanceOf(accounts[2]);
    let TotalSupplyA = await lendingPool.totalSupply();
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4egold, "ether") , web3.utils.fromWei(balanceAcc2AfterEGold, "ether"));
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4einr, "ether") , web3.utils.fromWei(balanceAcc2Aeinr, "ether"));
    assert.notEqual(web3.utils.fromWei(TotalSupplyB4, "ether") , web3.utils.fromWei(TotalSupplyA, "ether"));
  })

  it("User can Withdraw the Asset from the Lending Pool with Interest", async() =>{
    let TotalSupplyB4 = await lendingPool.totalSupply();
    let balanceAcc2B4einr = await eInrToken.balanceOf(accounts[1]);
    let AmountWithInterest = await lendingPool.getAmountWithInterest.call({from:accounts[2]});
    console.log(AmountWithInterest.toString(), "Interest calculated");
    let withdraw = await lendingPool.withDrawEINRToken(String(AmountWithInterest), {from: accounts[1]});
    let balanceAcc2Aeinr = await eInrToken.balanceOf(accounts[1]);
    let TotalSupplyA = await lendingPool.totalSupply();
    // console.log(web3.utils.fromWei(balanceAcc2B4einr, "ether"),"balanceAcc2B4einr")
    // console.log(web3.utils.fromWei(balanceAcc2Aeinr, "ether"),"balanceAcc2Aeinr")
    // console.log(web3.utils.fromWei(TotalSupplyB4,"ether"),"TotalSupplyB4")
    // console.log(web3.utils.fromWei(TotalSupplyA, "ether"),"TotalSupplyA")
    assert.notEqual(web3.utils.fromWei(balanceAcc2B4einr, "ether") , web3.utils.fromWei(balanceAcc2Aeinr, "ether"));
    assert.notEqual(web3.utils.fromWei(TotalSupplyB4, "ether") , web3.utils.fromWei(TotalSupplyA, "ether"));
  })

});
