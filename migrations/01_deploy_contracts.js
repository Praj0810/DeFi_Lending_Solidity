const EINRToken = artifacts.require("EINRToken");
const EGoldToken = artifacts.require("EGoldToken");
const LPToken = artifacts.require("LPToken");
const LendingPool = artifacts.require("LendingPool");

module.exports = async function(deployer, accounts, network){

    await deployer.deploy(EINRToken);
    const eInrToken = await EINRToken.deployed();
    await deployer.deploy(EGoldToken);
    const eGoldToken = await EGoldToken.deployed();
    await deployer.deploy(LPToken);
    const lpToken = await LPToken.deployed();   
    await deployer.deploy(LendingPool,eInrToken.address, eGoldToken.address, lpToken.address);
    const lendingBorrowing = await LendingPool.deployed();


    }