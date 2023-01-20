// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable {

    //provide the name and symbol of LP token 
    constructor()ERC20("LP Token", "LPT"){}


    //Minting LP token
    function mint(address account, uint256 amount)external onlyOwner{
        _mint(account, amount);
    }

    //Burning LP token reciept
    function burn(address account, uint256 amount)external onlyOwner{
        _burn(account, amount);
    }

}
