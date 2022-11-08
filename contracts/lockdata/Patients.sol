// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IPatient.sol";

contract Patient is ERC721Base, IPatient {
    mapping(uint256 => address) private _Patient;
    mapping(uint256 => bytes32) private _PatientHashValue;
    mapping(uint256 => mapping(address => bool)) private _isConsentDDR;
    DDR public _DDR;

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("Patient", "PT", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
    }

    function mint(
        bytes32 hashValue,
        string memory uri,
        address _identity
    ) public returns (uint256) {
        uint256 tokenId = super.mint(uri);
        _PatientHashValue[tokenId] = hashValue;
        _Patient[tokenId] = _identity;
        return tokenId;
    }

    function getAddress(uint256 tokenId) public view returns (address) {
        return _Patient[tokenId];
    }

    function getHashValue(uint256 tokenId)
        public
        view
        override
        returns (bytes32)
    {
        return _PatientHashValue[tokenId];
    }

    function getDDRofPatient(address _identity) public view returns (bytes32) {
        return _DDR.getDDRofPatient(_identity);
    }

    function consentDDRforClinic(
        uint256 _ddrId,
        uint256 tokenId,
        address _clinicAddress
    ) external override onlyClinic {
        require(
            _DDR.getShareApproval(_ddrId, _Patient[tokenId]),
            "Patient have not approval"
        );
        _isConsentDDR[_ddrId][_clinicAddress] = true;
        emit approval(_clinicAddress, _ddrId);
    }

    function getconsentDDR(uint256 _ddrId, address _clinicAddress)
        external
        view
        override
        onlyClinic
        returns (bool)
    {
        return _isConsentDDR[_ddrId][_clinicAddress];
    }
}
