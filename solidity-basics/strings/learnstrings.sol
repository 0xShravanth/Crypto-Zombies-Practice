// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//memory much like RAM in solidity. store data in a temporary place  then it will wipe it down
//storage stores data store data in a for longer time

contract learnstrings{
    string greetings = 'hello';

    function sayhii() public view returns(string memory){
        return greetings;
    }
    function changeGreetings(string memory _newGreeting) public {
        greetings = _newGreeting;
    }

    function getChar() public view returns(uint){
        bytes memory stringtoBytes = bytes(greetings);
        return stringtoBytes.length;
    }
}