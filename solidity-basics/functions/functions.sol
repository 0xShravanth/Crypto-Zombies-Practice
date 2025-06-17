// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// function 
/* function are the group of code which can be called anywhere in the code */

contract learnFunctions {
    /* function  function-name (parameter-list) scope returns(){
        statements;
         view helps in view return value
         //Purity:
Pure: The output depends only on the input parameters.
View:
A read-only view of storage or external data (e.g., blockchain variables).
    }*/
    function functionName() public pure returns(string memory){
        return "Hello World";
    }
     

    function remoteControlOpen(bool closeDoor) public pure returns(bool){
        if (closeDoor == true ){
            // Return false when door is closed, and 'return' will be used as a statement.
            return !true; 
        }
        return true;
    }

    function multiplyCalculator(uint a, uint b ) public pure returns(uint){
        return (a*b);
    }
    /*
    pure: When the function's output depends solely on input parameters without touching any internal state or external data.
View: For read-only views of storage, other contracts' data (without writing to them), and blockchain variables
    */
}