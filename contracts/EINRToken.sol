// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EINRToken is ERC20{
    //Address of EINRToken contract
    address public ownerINR;

    constructor() ERC20("EINR Token", "EINR"){
       ownerINR = msg.sender;
       _mint(msg.sender, 1000000 * 10 ** 18);
    }
   
}  
