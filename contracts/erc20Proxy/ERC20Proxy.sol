// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DID/ClaimHolder.sol";
import "../lockdata/DDR.sol";

contract ERC20Proxy {
    address public proxyOwner;
    DDR public ddr;

    address public pcoToken;
    uint256 private awardValue;
    address private tokenOwner;
    
    event ChangedAwardValue(uint256 newValue);
    event ChangedTokenOwner(address newOwner);
    event AwardedToken(address receiver, uint256 value);
    event ChangedPCOToken(address newPCOToken);
    event ChangedDDR(address newDDR);

    constructor(address _pcoAddress, address _tokenOwner, DDR _ddr) {
        proxyOwner = msg.sender;
        ddr = _ddr;
        pcoToken = _pcoAddress;
        tokenOwner = _tokenOwner;
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner, "Sender not match to proxy owner");
        _;
    }

    modifier onlyDDRContract() {
        require(msg.sender != address(0), "DDR is not set");
        require(msg.sender == address(ddr), "Sender not match to DDR contract");
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
        ddr = DDR(_ddrAddress);
        emit ChangedDDR(_ddrAddress);
    }

    function awardToken(address to) public onlyDDRContract {
        require(to != address(this), "Cannot award yourself");
        (bool success, ) = pcoToken.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", tokenOwner, to, awardValue)
        );
        require(success, "Award token failed");
        emit AwardedToken(to, awardValue);
    }
}