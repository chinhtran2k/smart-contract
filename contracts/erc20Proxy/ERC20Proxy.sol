// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DID/ClaimHolder.sol";

contract ERC20Proxy {
    address public proxyOwner;
    address public ddr;

    address public pcoToken;
    uint256 public awardValue;
    address public tokenOwner;
    
    event ChangedAwardValue(uint256 newValue);
    event ChangedTokenOwner(address newOwner);
    event AwardedToken(address receiver, uint256 value);
    event ChangedPCOToken(address newPCOToken);
    event ChangedDDR(address newDDR);

    constructor(address _pcoAddress, address _tokenOwner, address _ddr, uint256 _awardValue) {
        proxyOwner = msg.sender;
        ddr = _ddr;
        pcoToken = _pcoAddress;
        tokenOwner = _tokenOwner;
        awardValue = _awardValue;
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner, "Sender not match to proxy owner");
        _;
    }

    modifier onlyDDRContract() {
        require(msg.sender != address(0), "DDR is not set");
        require(msg.sender == ddr, "Sender not match to DDR contract");
        _;
    }

    function setAwardValue(uint _value) public onlyProxyOwner {
        awardValue = _value;
        emit ChangedAwardValue(_value);
    }

    function setTokenOwner(address _tokenOwner) public onlyProxyOwner {
        tokenOwner = _tokenOwner;
        emit ChangedTokenOwner(tokenOwner);
    }

    function setPCOToken(address _pcoAddress) public onlyProxyOwner {
        pcoToken = _pcoAddress;
        emit ChangedPCOToken(_pcoAddress);
    }

    function setDDRContract(address _ddrAddress) public onlyProxyOwner {
        ddr = _ddrAddress;
        emit ChangedDDR(_ddrAddress);
    }

    function awardToken(address to, uint256 numOfItem) public onlyDDRContract returns (bytes memory) {
        require(to != address(this), "Cannot award yourself");
        (bool success, bytes memory data) = pcoToken.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", tokenOwner, to, awardValue*numOfItem)
        );
        require(success, "Award token failed");
        emit AwardedToken(to, awardValue*numOfItem);
        return data;
    }
}