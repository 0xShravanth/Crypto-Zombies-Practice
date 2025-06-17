// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//if else statement 
// while statent
// = : asign value
// == : compare both value if value is equalvent
contract DecisionMaking {
    uint number = 5;

    function checknumber() public view returns(bool){
        if (number < 10){
            return true;
        }else{
            return false;
        }
    }
function iteratenumber() public view returns(uint){
    uint num = 0;
    while(num < number ){
        num = num + 1;
    }
    return num;
}


uint stakingwallet = 10;

function airDrop() public view returns(uint){
    if(stakingwallet == 10){
        return stakingwallet+10;
    }else {
        return stakingwallet +1;
    }
}

}