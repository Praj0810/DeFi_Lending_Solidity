// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EINRToken is ERC20{
    //Address of EINRToken contract
    address public ownerINR;
    
    /** 
    *@dev provide the name and the symbol of the token 
    * minting of EINR token for deployer is done here 
    */
    constructor() ERC20("EINR Token", "EINR"){
       ownerINR = msg.sender;
       _mint(msg.sender, 10000 * 10 ** 18);
    }
   
}  
