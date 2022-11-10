// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IPatient.sol";

contract Patient is ERC721Base, IPatient {
    mapping(uint256 => address) private _patient;
    mapping(address => bytes32) private _patientHashValue;
    mapping(uint256 => bytes32) private _patientHash;
    mapping(uint256 => mapping(address => bool)) private _isConsentDDR;
    bytes32 private _hashValue;
    DDR public _DDR;

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("Patient", "PT", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
    }

    function mint(address identity, string memory uri) public onlyPatient returns(uint256){
      uint256 tokenId = super.mint(uri);
      _hashValue = _DDR._ddrHashPatient(identity);
      _patientHashValue[identity] = _hashValue;
      _patientHash[tokenId] = _hashValue;
      _patient[tokenId] = identity;
    return tokenId;
    }

    function getAddressPatient(uint256 tokenId) public view returns (address) {
        return _patient[tokenId];
    }

    function getHashPatient(uint256 tokenId) public view returns (bytes32){
        return _patientHash[tokenId];
    }

    function getHashValuePatient(address identity) public view returns (bytes32){
        return _patientHashValue[identity];
    }

    function consentDDRforClinic(
        uint256 ddrTokenId,
        address identity,
        address clinicAddress
    ) external override onlyPatient {
        require(
            _DDR.getShareApproval(ddrTokenId, identity),
            "Patient have not approval"
        );
        _isConsentDDR[ddrTokenId][clinicAddress] = true;
        emit approval(clinicAddress, ddrTokenId);
    }

    function getconsentDDR(uint256 ddrTokenId, address clinicAddress)
        external
        view
        override
        onlyClinic
        returns (bool)
    {
        return _isConsentDDR[ddrTokenId][clinicAddress];
    }
}
