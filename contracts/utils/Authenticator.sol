// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interface/IAuthenticator.sol";
import "../DID/ClaimVerifier.sol";
import "../DID/ClaimHolder.sol";
import "../enum/AuthType.sol";

contract Authenticator is IAuthenticator {
    // mapping(address => bool) private _patient;
    // mapping(address => bool) private _provider;
    ClaimVerifier public _claimVerifier;

    constructor(address claimVerifier) {
        _claimVerifier = ClaimVerifier(claimVerifier);
    }

    function checkAuth(ClaimHolder _address, string memory _claimKey, string memory claimValue)
        public
        view
        override
        returns (bool result)
    {
        require(address(_address) != address(0), "Address zero is not allowed");

        if (_claimVerifier.claimIsValid(_address, _claimKey, claimValue)) {
            return true;
        }
    }
}

contract AuthenticatorHelper {
    IAuthenticator public _IAuth;

    constructor(address _authenticator) {
        require(_authenticator != address(0), "Address zero is not allowed");
        _IAuth = IAuthenticator(_authenticator);
    }

    modifier onlyPatient() {
        require(
            _IAuth.checkAuth(ClaimHolder(msg.sender), "ACCOUNT_TYPE", "PATIENT"),
            "Only Patient can call this function"
        );
        _;
    }

    modifier onlyProvider() {
        require(
            _IAuth.checkAuth(ClaimHolder(msg.sender), "ACCOUNT_TYPE", "PROVIDER"),
            "Only Provider can call this function"
        );
        _;
    }
}