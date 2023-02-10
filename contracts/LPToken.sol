// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {

    address public owner;
    //provide the name and symbol of LP token 
    constructor()ERC20("LP Token", "LPT"){
        owner = msg.sender;
    }

    //Minting LP token
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    //Burning LP token reciept
    function burn(address account, uint256 amount)external {
        _burn(account, amount);
    }

}
