const LendingPool = artifacts.require("LendingPool");
const LPToken = artifacts.require("LPToken");
const EGoldToken = artifacts.require("EGoldToken");
const EINRToken = artifacts.require("EINRToken");

contract("DeFi Lending App", accounts => {
  let eGoldToken, eInrToken, lpToken, lendingPool, eINRAmount, eGoldAmount;

  before(async () => {
    eGoldToken = await EGoldToken.deployed();
    console.log("EGoldToken", eGoldToken.address);
    lpToken = await LPToken.deployed();
    console.log("LPToken", lpToken.address);
    eInrToken = await EINRToken.deployed();
    console.log("EINRToken", eInrToken.address);
    lendingPool = await LendingPool.deployed();
    console.log("LendingPool", lendingPool.address);
  });

  it("All contract should get deployed properly", async () => {
    assert(eGoldToken.address !== "");
    assert(lpToken.address !== "");
    assert(eInrToken.address !== "");
    assert(lendingPool.address !== "");
  });

  it("1000000 EINR Token minted to Account[1]", async () => {
    let balanceEINRTokenOwner = await eInrToken.balanceOf(accounts[1], {
      from: accounts[1]
    });
    assert(balanceEINRTokenOwner == 1000000);
  });

  it("Deposit EINR in Lending Pool", async () => {
    let amount = eInrToken.balanceOf(accounts[1]);
    await eInrToken.approve(lendingPool.address, amount, {
      from: accounts[1]
    });
    await lendingPool.depositeINRToken(amount);
    //let totalSupply = await lendingPool.getBalanceEINR();
  });
});
