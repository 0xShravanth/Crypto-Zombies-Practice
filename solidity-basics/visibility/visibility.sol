// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract learnVisibility{
    // public : you can call the function outside as well as inside the smartcontract
    // private : you can only call the function inside the contract
    //internal : is slightly less restrictive than public
    // external:function can only be called from outsid of the contract 

    // state variable : defined globally  
    // local variable : defined inside the function scope is inside that function

    uint public number = 10; // visible to any contract in the project 
    uint private numberTwo = 56 ;// can only be accessed within this contract
    
    function changeNumber()public returns(uint) {
        number =number + 10;
        return  number ;
    }// note if we dont use modifier i.e view / pure then it will modify state variable

 function echangeNumbers()external view returns(uint) {
        uint numbers = number + 10;
        return  numbers ;
    }// note if we dont use modifier i.e view / pure then it will modify state variable

    function getnum() public view returns(uint) {
        return number;
    }
}
