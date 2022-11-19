// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../enum/AuthType.sol";
import "../interface/IDDR.sol";
import "../erc20Proxy/ERC20Proxy.sol";
import "../DID/ClaimHolder.sol";

contract DDR is ERC721Base, IDDR {
    ERC20Proxy public erc20Proxy;
    ClaimHolder public claimHolder;

    mapping(address => bytes32) private _ddrHashPatient;


    // this allow to query DDR by ddrID
    mapping(bytes32 => uint256) private _ddrHashedId;
    mapping(uint256 => string) private _ddrPatientRawId;
    mapping(uint256 => bytes32) private _ddrHash;
    mapping(uint256 => bytes32) private _ddrHashedData;

    mapping(uint256 => bool) private _isDDRLocked;
    mapping(uint256 => mapping(address => bool)) private _isSharedDDR;
    mapping(uint256 => mapping(address => bool)) private _isConsentedDDR;
    mapping(uint256 => address) private _patient;
    mapping(address => uint256[]) private _listDDRHashValueOfPatient;

    struct TokenInfo {
        string ddrRawId;
        string ddrPatientRawId;
        bytes32 hashedData;
        bytes32 hashValue;
        address patient;
    }

    mapping(uint256 => TokenInfo) private Tokens;

    bytes32 private _hashValuePatient;

    modifier _valiDDRList(uint256 ddrId, address senderAddress) {
        require(!_isDDRLocked[ddrId], "DDR is already locked.");
        require(ownerOf(ddrId) == senderAddress, "Not owner of ddr.");
        _;
    }

    modifier onlyClaimHolder() {
        require(
            address(claimHolder) == msg.sender,
            "Only ClaimHolder can call this function."
        );
        _;
    }

    constructor(address _claimHolderAddress, address _authAddress)
        ERC721Base("Drug Dispense Report", "DDR", _authAddress)
    {
        claimHolder = ClaimHolder(_claimHolderAddress);
    }

    function getDDRHash(uint256 tokenId) public view returns (bytes32) {
        return _ddrHash[tokenId];
    }

    function getDDRPatientRawId(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _ddrPatientRawId[tokenId];
    }

    function getDDRHashByRawId(string memory ddrRawId) public view returns (bytes32) {
        bytes32 hashedRawId = keccak256(abi.encodePacked(ddrRawId));
        uint256 tokenId = _ddrHashedId[hashedRawId];
        return _ddrHash[tokenId];
    }

    function getToken(uint256 tokenId) public view returns (
        string memory ddrRawId, 
        string memory ddrPatientRawId,
        bytes32 hashedData,
        bytes32 hashValue,
        address patient
        ) 
    {
        return (Tokens[tokenId].ddrRawId,
            Tokens[tokenId].ddrPatientRawId,
            Tokens[tokenId].hashedData,
            Tokens[tokenId].hashValue,
            Tokens[tokenId].patient
        );
    }

    function mint(
        bytes32 hashedData,
        string memory ddrRawId,
        string memory ddrPatientRawId,
        string memory uri,
        address patientDID
    ) public onlyClaimHolder returns (uint256) {
        // TODO: need to check valid patientDID
        require(checkAuthDID(patientDID) == AuthType.PATIENT, "Patient DID is not valid!");

        uint256 tokenId = super.mint(uri);
        _patient[tokenId] = patientDID;
        
        // Create DDR hash value base on DID and hashed data
        bytes32 newHashValue = keccak256(abi.encodePacked(ddrRawId, hashedData));
        bytes32 hashedRawId = keccak256(abi.encodePacked(ddrRawId));
        require(_ddrHashedId[hashedRawId] == 0x00, "DDR mint error: DDRID exist!");

        // Assign data to map
        _ddrHashedId[hashedRawId] = tokenId;
        _ddrPatientRawId[tokenId] = ddrPatientRawId;
        _ddrHashedData[tokenId] = hashedData;
        _ddrHash[tokenId] = newHashValue;
        _patient[tokenId] = patientDID;
        _listDDRHashValueOfPatient[patientDID].push(tokenId);

        // Assign data to token info
        Tokens[tokenId].ddrRawId = ddrRawId;
        Tokens[tokenId].ddrPatientRawId = ddrPatientRawId;
        Tokens[tokenId].hashedData = hashedData;
        Tokens[tokenId].hashValue = newHashValue;
        Tokens[tokenId].patient = patientDID;

        _isDDRLocked[tokenId - 1] = true;
        emit MintedDDR(ddrRawId, 
            ddrPatientRawId,
            hashedData,
            newHashValue,
            patientDID);
        emit DDRTokenLocked(tokenId-1);

        return tokenId;
    }

    function mintBatch(
        bytes32[] memory hashedDatas,
        string[] memory ddrRawIds,
        string[] memory ddrPatientRawIds,
        string[] memory uris,
        address patientDID
    ) public onlyClaimHolder returns (uint256[] memory) {
        require(hashedDatas.length == ddrRawIds.length, "DDR mint error: length of hashedData and ddrRawId is not equal!");
        require(hashedDatas.length == uris.length, "DDR mint error: length of hashedData and uri is not equal!");
        require(hashedDatas.length == ddrPatientRawIds.length, "DDR mint error: length of hashedData and ddrPatientRawId is not equal!");

        uint256[] memory tokenIds = new uint256[](hashedDatas.length);
        for (uint256 i = 0; i < hashedDatas.length; i++) {
            tokenIds[i] = mint(hashedDatas[i], ddrRawIds[i], ddrPatientRawIds[i], uris[i], patientDID);
        }
        return tokenIds;
    }

    function setERC20Proxy(address _erc20Proxy) public onlyOwner {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
    }

    function getListDDRHashValueOfPatient(address patientDID) public view returns (uint256[] memory) {
        return _listDDRHashValueOfPatient[patientDID];
    }

    function patientOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        address _owner = _patient[tokenId];
        require(_owner != address(0), "ERC721: invalid token ID");
        return _owner;
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
    // "shareDDR" only use by ClaimHolder
    function shareDDR(uint256 ddrTokenId, address patientDID) public onlyClaimHolder
    {
        _isSharedDDR[ddrTokenId][patientDID];
        emit ApprovalShareDDR(patientDID, ddrTokenId);
        erc20Proxy.awardToken(patientDID);
    }

    // "disclosureConsentDDRFromProvider" only use for Patient
    function disclosureConsentDDRFromProvider(uint256[] memory ddrTokenIds, address providerDID) public onlyPatient {
        for (uint i=0; i < ddrTokenIds.length; i++) {
            _isConsentedDDR[ddrTokenIds[i]][providerDID] = true;
        }
        emit ApprovalDisclosureConsentDDR(msg.sender, providerDID, ddrTokenIds);
        erc20Proxy.awardToken(tx.origin);
    }

    
}
