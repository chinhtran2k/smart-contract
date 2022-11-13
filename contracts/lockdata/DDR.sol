// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../enum/AuthType.sol";
import "../interface/IDDR.sol";

contract DDR is ERC721Base, IDDR {
    mapping(address => bytes32) private _ddrHashPatient;
    mapping(address => bytes32) private _ddrHashPharmacy;

    // this allow to query DDR by ddrID
    mapping(bytes32 => uint256) private _ddrRawId;
    mapping(uint256 => bytes32) private _ddrHash;
    mapping(uint256 => bytes32) private _ddrHashedData;

    mapping(uint256 => bool) private _isDDRLocked;
    mapping(uint256 => mapping(address => bool)) private _isSharedDDR;
    mapping(uint256 => mapping(address => bool)) private _isConsentedDDR;
    mapping(uint256 => address) private _patient;
    mapping(address => uint256[]) private _listDDRHashValueOfPatient;
    mapping(address => uint256[]) private _listDDRHashValueOfPharmacy;

    struct TokenInfo {
        string ddrRawId;
        bytes32 hashedData;
        bytes32 hashValue;
        address pharmacy;
        address patient;
    }

    mapping(uint256 => TokenInfo) private Tokens;

    bytes32 private _hashValuePatient;
    bytes32 private _hashValuePharmacy;

    modifier _valiDDRList(uint256 ddrId, address senderAddress) {
        require(!_isDDRLocked[ddrId], "DDR is already locked.");
        require(ownerOf(ddrId) == senderAddress, "Not owner of ddr.");
        _;
    }

    constructor(address _authAddress)
        ERC721Base("Drug Dispense Report", "DDR", _authAddress)
    {}

    function getDDRHash(uint256 tokenId) public view returns (bytes32) {
        return _ddrHash[tokenId];
    }

    function getDDRHashByRawId(string memory ddrRawId) public view returns (bytes32) {
        bytes32 hashedRawId = keccak256(abi.encodePacked(ddrRawId));
        uint256 tokenId = _ddrRawId[hashedRawId];
        return _ddrHash[tokenId];
    }

    function getToken(uint256 tokenId) public view returns (
        string memory ddrRawId, 
        bytes32 hashedData,
        bytes32 hashValue,
        address pharmacy,
        address patient
        ) 
    {
        return (Tokens[tokenId].ddrRawId,
            Tokens[tokenId].hashedData,
            Tokens[tokenId].hashValue,
            Tokens[tokenId].pharmacy,
            Tokens[tokenId].patient
        );
    }

    function mint(
        bytes32 hashedData,
        string memory ddrRawId,
        string memory uri,
        address patientDID
    ) public onlyPharmacy returns (uint256) {
        // TODO: need to check valid patientDID
        require(checkAuthDID(patientDID) == AuthType.PATIENT, "Patient DID is not valid!");

        uint256 tokenId = super.mint(uri);
        _patient[tokenId] = patientDID;
        
        // Create DDR hash value base on DID and hashed data
        bytes32 newHashValue = keccak256(abi.encodePacked(ddrRawId, hashedData));
        bytes32 hashedRawId = keccak256(abi.encodePacked(ddrRawId));
        require(_ddrRawId[hashedRawId] == 0x00, "DDR mint error: DDRID exist!");

        // Assign data to map
        _ddrRawId[hashedRawId] = tokenId;
        _ddrHashedData[tokenId] = hashedData;
        _ddrHash[tokenId] = newHashValue;
        _patient[tokenId] = patientDID;
        _listDDRHashValueOfPatient[patientDID].push(tokenId);
        _listDDRHashValueOfPharmacy[msg.sender].push(tokenId);

        // Assign data to token info
        Tokens[tokenId].ddrRawId = ddrRawId;
        Tokens[tokenId].hashedData = hashedData;
        Tokens[tokenId].hashValue = newHashValue;
        Tokens[tokenId].pharmacy = address(msg.sender);
        Tokens[tokenId].patient = patientDID;


        _isSharedDDR[tokenId][patientDID] = true;
        _isDDRLocked[tokenId - 1] = true;
        emit MintedDDR(ddrRawId, 
            hashedData,
            newHashValue,
            msg.sender,
            patientDID);
        emit ApprovalShareDDR(msg.sender, patientDID, tokenId);
        emit DDRTokenLocked(tokenId-1);

        return tokenId;
    }

    function getListDDRHashValueOfPatient(address patientDID) public view returns (uint256[] memory) {
        return _listDDRHashValueOfPatient[patientDID];
    }

    function getListDDRHashValueOfPharmacy(address pharmacyDID) public view returns (uint256[] memory) {
        return _listDDRHashValueOfPharmacy[pharmacyDID];
    }

    function patientOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        address owner = _patient[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function pharmacyOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        address owner = ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    //// Status part
    function isLockedDDR(uint256 tokenId) public view returns (bool) {
        return _isDDRLocked[tokenId];
    }

    function isSharedDDR(address identity, uint256 ddrTokenId) public view returns (bool) {
        return _isConsentedDDR[ddrTokenId][identity];
    }

    function isConsentedDDR(address identity, uint256 ddrTokenId) public view returns (bool)
    {
        return _isConsentedDDR[ddrTokenId][identity];
    }

    //// Approval part
    // "shareDDRFromPharmacy" only use for Pharmacy
    function shareDDRFromPharmacy(uint256 ddrTokenId, address patientDID) public onlyPharmacy
    {
        _isSharedDDR[ddrTokenId][patientDID];
        emit ApprovalShareDDR(msg.sender, patientDID, ddrTokenId);
    }

    // "disclosureConsentDDRFromHospital" only use for Patient
    function disclosureConsentDDRFromHospital(uint256[] memory ddrTokenIds, address hospitalDID) public onlyPatient {
        for (uint i=0; i < ddrTokenIds.length; i++) {
            _isConsentedDDR[ddrTokenIds[i]][hospitalDID] = true;
        }
        emit ApprovalDisclosureConsentDDR(msg.sender, hospitalDID, ddrTokenIds);
    }

    
}
