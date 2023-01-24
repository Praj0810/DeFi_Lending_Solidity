// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//collateral token
contract EGoldToken is ERC20{
    //Address of EINRToken contract
    address public ownerGold;

    constructor() ERC20("EGold Token", "EGold"){
       ownerGold = msg.sender;
    }

     function mint(address account, uint256 amount)external {
        _mint(account, amount);
    }
   
}