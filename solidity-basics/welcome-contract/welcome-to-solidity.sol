// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract WelcomeToSolidity{
    constructor()  {}

    function getResult() public pure returns(uint){
        uint a = 1;
        uint b = 2;
        uint result = a + b;
        return result;
    }

}