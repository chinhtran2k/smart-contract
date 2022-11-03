// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/IAuthenticator.sol";
import "../../../hpa3-blockchain-did/contracts/ClaimVerifier.sol";
import "../../../hpa3-blockchain-did/contracts/ClaimHolder.sol";

contract Authenticator is IAuthenticator {
    mapping(address => bool) private _pharmacy;
    mapping(address => bool) private _patient;
    mapping(address => bool) private _clinic;
    ClaimVerifier private _checkClaim;

    constructor(address claimVerifier) {
        _pharmacy[msg.sender] = true;
        _patient[msg.sender] = true;
        _clinic[msg.sender] = true;
        _checkClaim = ClaimVerifier(claimVerifier);
    }

    function createDID(ClaimHolder _address) external {
        require(address(_address) != address(0), "Address zero is not allowed");
        require(_pharmacy[msg.sender] == true, "Address is not pharmacy");
        require(_patient[msg.sender] == true, "Address is not patient");
        require(_clinic[msg.sender] == true, "Address is not clinic");
        if (_checkClaim.checkClaim(_address, 1)) {
            _patient[address(_address)] = true;
        } else if (_checkClaim.checkClaim(_address, 2)) {
            _pharmacy[address(_address)] = true;
        } else if (_checkClaim.checkClaim(_address, 3)) {
            _clinic[address(_address)] = true;
        }
    }

    function checkAuth(address _address)
        external
        view
        override
        returns (AuthType)
    {
        require(_address != address(0), "Address zero is not allowed");
        if (_patient[_address]) return AuthType.PT;
        else if (_pharmacy[_address]) return AuthType.PM;
        else if (_clinic[_address]) return AuthType.CN;
        else return AuthType.NONE;
    }
}

contract AuthenticatorHelper {
    IAuthenticator private _IAuth;

    constructor(address _authenticator) {
        require(_authenticator != address(0), "Address zero is not allowed");
        _IAuth = IAuthenticator(_authenticator);
    }

    modifier onlyPharmacy() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PM,
            "Only pharmacy can call this function"
        );
        _;
    }

    modifier onlyPatient() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.PT,
            "Only patient can call this function"
        );
        _;
    }

    modifier onlyClinic() {
        require(
            _IAuth.checkAuth(msg.sender) == AuthType.CN,
            "Only clinic can call this function"
        );
        _;
}
