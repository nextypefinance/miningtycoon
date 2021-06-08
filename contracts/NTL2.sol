// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract NTL2 is ERC20, Ownable {

    /**
     * @dev Sets the {name} and {symbol} of token.
     * Initializes {decimals} with a default value of 18.
     * Mints all tokens.
     * Transfers ownership to another account. So, the token creator will not be counted as an owner.
     */
    constructor() public ERC20("NEXTYPE License 2", "NT-L2") {
        uint256 supply        = 1000000000 * (10 ** 18);
   
        _mint(_msgSender(),       supply);

    }


    function mintToken(uint256 mintedAmount) public onlyOwner returns (bool success){
        
         _mint(_msgSender(),       mintedAmount);
         
        return true;
    }
}

