// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//collateral token
contract EGoldToken is ERC20{
    //Address of EINRToken contract
    address public ownerGold;

    constructor() ERC20("EGold Token", "EGold"){
       ownerGold = msg.sender;
       _mint(msg.sender, 2000000 * 10 ** 18);
    }
    
   
}