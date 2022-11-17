// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interface/IAuthenticator.sol";
import "../DID/ClaimVerifier.sol";
import "../DID/ClaimHolder.sol";
import "../enum/AuthType.sol";

contract Authenticator is IAuthenticator {
    mapping(address => bool) private _patient;
    mapping(address => bool) private _provider;
    ClaimVerifier public _claimVerifier;

    constructor(address claimVerifier) {
        _claimVerifier = ClaimVerifier(claimVerifier);
    }

    function createAuthentication(ClaimHolder _address, AuthType _claimType) public {
        require(address(_address) != address(0), "Address zero is not allowed");
        
        bool isCreated = false;

        if (_claimType == AuthType.PATIENT) {
            _claimVerifier.checkClaim(_address, 1);
            _patient[address(_address)] = true;
            isCreated = true;
            emit CreatedAuthentication(address(_address), AuthType.PATIENT);
        } else if (_claimType == AuthType.PROVIDER) {
            _claimVerifier.checkClaim(_address, 2);
            _provider[address(_address)] = true;
            isCreated = true;
            emit CreatedAuthentication(address(_address), AuthType.PROVIDER);
        } else {
            revert("Address not has valid claim");
        }

        require(isCreated, "This DID is not valid!");
    }

    function checkAuth(address _address)
        external
        view
        override
        returns (AuthType)
    {
        require(_address != address(0), "Address zero is not allowed");
        if (_patient[_address]) {return AuthType.PATIENT;}
        else if (_provider[_address]) {return AuthType.PROVIDER;}
        else {return AuthType.NONE;}
    }
}

contract AuthenticatorHelper {
    IAuthenticator public _IAuth;

    constructor(address _authenticator) {
        require(_authenticator != address(0), "Address zero is not allowed");
        _IAuth = IAuthenticator(_authenticator);
    }

    function checkAuthDID(address _address)
        public
        view
        returns (AuthType)
{
        require(_address != address(0), "Address zero is not allowed");
        if (_IAuth.checkAuth(_address) == AuthType.PATIENT) {return AuthType.PATIENT;}
        else if (_IAuth.checkAuth(_address) == AuthType.PROVIDER) {return AuthType.PROVIDER;}
        else {return AuthType.NONE;}
    }

    modifier onlyPatient() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PATIENT,
            "Only Patient can call this function"
        );
        _;
    }

    modifier onlyProvider() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PROVIDER,
            "Only Provider can call this function"
        );
        _;
    }
}