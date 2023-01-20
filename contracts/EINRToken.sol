// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EINRToken is ERC20{
    //Address of EINRToken contract
    //address public tokenOwner;

    constructor() ERC20("EINR Token", "EINR"){
       // tokenOwner = msg.sender;
    }

     function mint(address account, uint256 amount)external {
        _mint(account, amount);
    }
   
}