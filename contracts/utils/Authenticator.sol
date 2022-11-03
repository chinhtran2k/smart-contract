// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/IAuthenticator.sol";

contract Authenticator is IAuthenticator {
    // mapping(address => bool) private _subject;
    // mapping(address => bool) private _administrator;
    // mapping(address => bool) private _actor;
    mapping(address => bool) private _patients;
    mapping(address => bool) private _clinic;
    mapping(address => bool) private _pharmacy;

    constructor() {
        // _administrator[msg.sender] = true;
        _patients[msg.sender] = true;
    }

    function createDID(address _address, AuthType authType) external {
        require(_address != address(0), "Address zero is not allowed");
        require(
            _patients[msg.sender] == true,
            "Address is not Patients"
        );
        if (_patients[_address] && authType != AuthType.PATIENTS)
            _patients[_address] = false;
        if (_clinic[_address] && authType != AuthType.CLINIC)
            _clinic[_address] = false;
        if (_patients[_address] && authType != AuthType.PHARMACY)
            _pharmacy[_address] = false;
        else if (authType == AuthType.PATIENTS) _patients[_address] = true;
        else if (authType == AuthType.CLINIC) _clinic[_address] = true;
        else if (authType == AuthType.PHARMACY) _pharmacy[_address] = true;

    }

    function checkAuth(address _address)
        external
        view
        override
        returns (AuthType)
    {
        require(_address != address(0), "Address zero is not allowed");
        if(_patients[_address]) return AuthType.PATIENTS;
        if(_clinic[_address]) return AuthType.CLINIC;
        if(_pharmacy[_address]) return AuthType.PHARMACY;
        else return AuthType.NONE;
    }

}

contract AuthenticatorHelper {
    IAuthenticator private _IAuth;

    constructor(address _authenticator) {
        require(_authenticator != address(0), "Address zero is not allowed");
        _IAuth = IAuthenticator(_authenticator);
    }

    modifier onlyClinic() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.CLINIC,
            "Only Clinic can call this function"
        );
        _;
    }

    modifier onlyPatients() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PATIENTS,
            "Only patients can call this function"
        );
        _;
    }

    modifier onlyPharmacy() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PHARMACY,
            "Only Pharmacy can call this function"
        );
        _;
    }
}
