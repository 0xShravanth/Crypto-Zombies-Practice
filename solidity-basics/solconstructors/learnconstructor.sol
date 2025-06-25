// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Member{
    string name;
    uint age;

    constructor (string memory _name, uint _age) public {
        name = _name;
        age = _age;
    }
}
contract Teacher is Member('sager',24)
 {
    //onstructor(string memory n, uint a) Member(n, a) public {}
    function getName() public view returns(string memory){
        return name;
    }

}
