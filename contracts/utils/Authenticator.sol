// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/IAuthenticator.sol";

contract Authenticator is IAuthenticator {
    // mapping(address => bool) private _subject;
    // mapping(address => bool) private _administrator;
    // mapping(address => bool) private _actor;
    mapping(address => bool) private _patients;

    constructor() {
        // _administrator[msg.sender] = true;
        _patients[msg.sender] = true;
    }

    function createDID(address _address, AuthType authType) external {
        require(_address != address(0), "Address zero is not allowed");
        require(
            _patients[msg.sender] == true,
            "Address is not healthRecord"
        );
        // if checkClaim(address A, 1) => patient
        // else if checkClaim(address A, 2) => Pharmacy
        // if (_subject[_address] && authType != AuthType.SB)
        //     _subject[_address] = false;
        if (_patients[_address] && authType != AuthType.PT)
            _patients[_address] = false;
        // if (_actor[_address] && authType != AuthType.IV)
        //     _actor[_address] = false;

        // if (authType == AuthType.SB) _subject[_address] = true;
        else if (authType == AuthType.PT) _patients[_address] = true;
        // else if (authType == AuthType.IV) _actor[_address] = true;
    }

    function checkAuth(address _address)
        external
        view
        override
        returns (AuthType)
    {
        require(_address != address(0), "Address zero is not allowed");
        if(_patients[_address]) return AuthType.PT;
        // if (_subject[_address]) return AuthType.SB;
        // else if (_administrator[_address]) return AuthType.AD;
        // else if (_actor[_address]) return AuthType.IV;
        else return AuthType.NONE;
    }

}

contract AuthenticatorHelper {
    IAuthenticator private _IAuth;

    constructor(address _authenticator) {
        require(_authenticator != address(0), "Address zero is not allowed");
        _IAuth = IAuthenticator(_authenticator);
    }

    // modifier onlyClinic() {
    //     require(
    //         _IAuth.checkAuth(msg.sender) == AuthType.CL,
    //         "Only actor_clinic can call this function"
    //     );
    //     _;
    // }

    modifier onlyPatients() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PT,
            "Only patients can call this function"
        );
        _;
    }

}
