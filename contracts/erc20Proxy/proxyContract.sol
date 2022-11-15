// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../DID/ClaimHolder.sol";
import "../interface/IPCO.sol";
import "./PCO.sol";

contract ProxyContract {
    PCO public token;
    ClaimHolder public identity;
    uint256 private awardUserValue;
    address public userAddress;
    address private ownerAddress;
    constructor(address _pcoAddress, address _ownerAddress, address _identity) {
        token = PCO(_pcoAddress);
        identity = ClaimHolder(_identity);
        ownerAddress = _ownerAddress;
    }

    function setUserAwardValue(uint _value) public {
        awardUserValue = _value;
    }

    function setOwner() public returns(address){
        userAddress = identity.owner();
    }

    function awardToken() external  {
        require(userAddress != address(this), "Cannot award yourself");
        token.transferFrom(ownerAddress, userAddress, awardUserValue);
    }
}