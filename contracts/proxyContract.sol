// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../hpa3-blockchain/contracts/ClaimHolder.sol";
import "./interface/IPCO.sol";
import "./PCO.sol";

contract ProxyContract {
    PCO public token;
    ClaimHolder public identity;
    uint256 private awardUserValue;
    address private ownerAddress;
    constructor(address _pcoAddress, address _ownerAddress, address _identity) {
        token = PCO(_pcoAddress);
        identity = ClaimHolder(_identity);
        ownerAddress = _ownerAddress;
    }

    function setUserAwardValue(uint _value) public {
        awardUserValue = _value;
    }

    // function setOwner() public view returns(address){
    //     identity.owner();
    // }

    function setOwner(ClaimHolder inden) public view returns(address){
        inden.owner();
    }
    function awardToken() external  {
        token.transferFrom(ownerAddress, identity.owner(), awardUserValue);
    }
}