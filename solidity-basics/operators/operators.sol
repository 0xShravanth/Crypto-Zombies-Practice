// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// operator
/* operator: its a symbol thatv tells compiler ot interpeter to perform specific mathematic , relational or logical operation and produce final result*/
// arithmetic Operators
/* +   -    *    /    %  ++  -- */
// comparision Operaor
/* <= , >= , == */

//Operands : variables
/* in a+b a and b operands + is operator*/

// operators: signs

contract LearnOperators  {
    function calculator()public pure returns(uint){
        uint a = 5;
        uint b = 10;
        return a + b;
    }

    function compare() public pure {
        uint c = 5;
        uint d =  10;
         bool result = (c > d);
        require( result ,"false");
        // require (calculator() > 2,"failed"); 
        // require is a method to check the function is true if true it will run the function
    }

}