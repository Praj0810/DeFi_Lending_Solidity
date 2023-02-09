const EINRToken = artifacts.require("EINRToken");
const EGoldToken = artifacts.require("EGoldToken");
const LPToken = artifacts.require("LPToken");
const LendingPool = artifacts.require("LendingPool");

module.exports = async function(deployer, accounts){

    await deployer.deploy(EINRToken);
    await deployer.deploy(EGoldToken);
    await deployer.deploy(LPToken);

    const eInrToken = await EINRToken.deployed();
    const eGoldToken = await EGoldToken.deployed();
    const lpToken = await LPToken.deployed();

    await deployer.deploy(LendingPool,eInrToken.address, eGoldToken.address, lpToken.address);
    const lendingBorrowing = await LendingPool.deployed();

    }