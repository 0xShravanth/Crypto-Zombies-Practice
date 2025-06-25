// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract loopContract{

    function checkMultiples(uint _num , uint _nums)public pure returns(bool) {
        if(_num%_nums==0){
            return true;
        }else{ 
            return false;
            }

    }

    function checkNumbers(uint _num) public pure returns(uint){
        uint count = 0;
        for (uint i=1 ;i <=_num ; ++i ) {
            if(_num%i==0 &&checkMultiples(_num,2)){
                continue;
            }else{
                ++count; 
                 
            }
        }
        return count;  
    }
}

// while and do while loops cans also be used in solidity