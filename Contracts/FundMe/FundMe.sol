// Get Funds
// Withdraw funds
// set a minimum funding value in usd

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error NotOwner();


contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD =  1 * 10 ** 18;
    address[] public funders;
    address public i_owner; /*immutable*/
    // mapping (address => uint256) public addressToAmount;
    mapping (address funder => uint256 amountFounded) public addressToAmountFounded;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner(){
        if(msg.sender != i_owner) revert NotOwner();
        _;
    }
    


    function fund() public payable {
        // allow user to send money 
        //require(msg.value >= MINIMUM_USD,"didn't send enough eth. minimum requirement (1e18 eth)");
        require(msg.value.getConversionRate() >= MINIMUM_USD,"didn't send enough eth. minimum requirement :1 eth");
        funders.push(msg.sender);
        addressToAmountFounded[msg.sender] += msg.value;
    }
    
    function withdraw() public onlyOwner{
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFounded[funder] = 0;
        }
        funders = new address[](0);
        //call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"call failed");
        
        // or call returns 2 data either capture 2 data or capture only one  
//         (bool callsSuccess, bytes memory returnedData) = payable(msg.sender).call{value: address(this).balance}("");
// require(callsSuccess, string(abi.encodePacked("Call failed. Returned data: ", returnedData)));
        
        // -- transfer
        // payable(msg.sender).transfer(address(this).balance);

        // -- send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");



    }
    fallback() external payable {
        fund();
     }

     receive() external payable { 
        fund();
     }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }


    // 
}
// revert - undo the action that have been done and send back the remaining gas