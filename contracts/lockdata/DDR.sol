// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../enum/AuthType.sol";
import "../interface/IDDR.sol";
import "../erc20Proxy/ERC20Proxy.sol";
import "../DID/ClaimHolder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DDR is ERC721Base, IDDR {
    ERC20Proxy public erc20Proxy;
    ClaimHolder public claimHolder;

    mapping(address => bytes32) private _ddrHashPatient;


    // this allow to query DDR by ddrID
    mapping(bytes32 => uint256) private _ddrHashedId;
    mapping(uint256 => bytes32) private _ddrHash;
    mapping(uint256 => bytes32) private _ddrHashedData;

    mapping(uint256 => bool) private _isDDRLocked;
    mapping(uint256 => mapping(address => bool)) private _isSharedDDR;
    mapping(uint256 => mapping(address => bool)) private _isConsentedDDR;
    mapping(uint256 => address) private _patient;
    mapping(uint256 => address[]) private _didConsentedOf;
    mapping(address => uint256[]) private _listDDRTokenIdOfPatient;
    mapping(address => uint256[]) private _listDDRTokenIdOfProvider;
    mapping(uint256 => string) private _ddrId;

    bytes32 private _hashStringPatient;

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

    function getTokenIdOfPatientDIDByRawId(address patientDID, string memory ddrRawId) public view returns (uint256) {
        return _ddrHashedId[keccak256(abi.encodePacked(patientDID, ddrRawId))];
    }

    function getDDRHashOfPatientDIDByRawId(address patientDID, string memory ddrRawId) public view returns (bytes32) {
        bytes32 hashedRawId = keccak256(abi.encodePacked(patientDID, ddrRawId));
        uint256 tokenId = _ddrHashedId[hashedRawId];
        return _ddrHash[tokenId];
    }

    function getToken(uint256 tokenId) public view returns (
        address patientDID, 
        string memory ddrId,
        bytes32 ddrHashedData,
        bytes32 ddrHash,
        address[] memory didConsentedOf
        ) 
    {
        return (
            _patient[tokenId],
            _ddrId[tokenId],
            _ddrHashedData[tokenId],
            _ddrHash[tokenId],
            _didConsentedOf[tokenId]
        );
    }

    function setTokenInfo(
            uint256 tokenId, 
            bytes32 hashedData,
            string memory ddrRawId,
            address patientDID
        ) 
        internal returns (bytes32)
    {
        _patient[tokenId] = patientDID;
        
        // Create DDR hash value base on DID and hashed data
        bytes32 newHashValue = keccak256(abi.encodePacked(patientDID, ddrRawId, hashedData));
        bytes32 hashedRawId = keccak256(abi.encodePacked(patientDID, ddrRawId));
        require(_ddrHashedId[hashedRawId] == 0x00, "DDR mint error: DDRID exist!");

        // Assign data to map
        _ddrHashedId[hashedRawId] = tokenId;
        _ddrHashedData[tokenId] = hashedData;
        _ddrHash[tokenId] = newHashValue;
        _patient[tokenId] = patientDID;
        _listDDRTokenIdOfPatient[patientDID].push(tokenId);
        _ddrId[tokenId] = ddrRawId;
        
        _isDDRLocked[tokenId - 1] = true;

        return newHashValue;
    }

    function mint(
        bytes32 hashedData,
        string memory ddrRawId,
        string memory uri,
        address patientDID
    ) public onlyClaimHolder returns (uint256) {
        require(_IAuth.checkAuth(ClaimHolder(patientDID), "PATIENT"), "Patient DID is not valid!");
        require(bytes(ddrRawId).length > 0, "DDR ID is empty!");
        ClaimHolder patient = ClaimHolder(patientDID);

        uint256 tokenId = super.mintTo(patient.owner(), uri);
        bytes32 newHashValue = setTokenInfo(tokenId, hashedData, ddrRawId, patientDID);
        
        emit MintedDDR(tokenId,
            ddrRawId,
            hashedData,
            newHashValue,
            patientDID);
        emit DDRTokenLocked(tokenId-1);

        return tokenId;
    }

    function mintBatch(
        bytes32[] memory hashedDatas,
        string[] memory ddrRawIds,
        string[] memory uris,
        address patientDID
    ) public onlyClaimHolder returns (uint256[] memory) {
        require(hashedDatas.length == ddrRawIds.length, "DDR mint error: length of hashedData and ddrRawId is not equal!");
        require(hashedDatas.length == uris.length, "DDR mint error: length of hashedData and uri is not equal!");

        // check ddrId
        for (uint256 i = 0; i < ddrRawIds.length; i++) {
            require(bytes(ddrRawIds[i]).length > 0, "DDR ID is empty!");
        }

        // uint256[] memory tokenIds = new uint256[](hashedDatas.length);
        uint256[] memory tokenIds = mintBatchTo(patientDID, uris);
        bytes32[] memory newHashValues = new bytes32[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            newHashValues[i] = setTokenInfo(tokenIds[i], hashedDatas[i], ddrRawIds[i], patientDID);
        }

        emit MintedBatchDDR(tokenIds, ddrRawIds, hashedDatas, newHashValues, patientDID);

        return tokenIds;
    }

    function setERC20Proxy(address _erc20Proxy) public onlyOwner {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
    }

    function getListDDRTokenIdOfPatient(address patientDID) public view returns (uint256[] memory) {
        return _listDDRTokenIdOfPatient[patientDID];
    }

    function getListDDRTokenIdOfProvider(address providerDID) public view returns (uint256[] memory) {
        return _listDDRTokenIdOfProvider[providerDID];
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
        return _isSharedDDR[ddrTokenId][identity];
    }

    function isConsentedDDR(address identity, uint256 ddrTokenId) public view returns (bool)
    {
        return _isConsentedDDR[ddrTokenId][identity];
    }

    function getDIDConsentedOf(uint256 tokenId) public view returns (address[] memory) {
        return _didConsentedOf[tokenId];
    }

    //// Approval part
    // "shareDDR" only use by ClaimHolder
    function shareDDR(uint256[] memory ddrTokenIds, address patientDID) public onlyClaimHolder {
        ClaimHolder tempPatient = ClaimHolder(patientDID);

        // check if token is shared
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            require(_ddrHash[ddrTokenIds[i]] != 0x00, "tokenId not exist, revert transaction");
            require(_isSharedDDR[ddrTokenIds[i]][patientDID] != true, string(abi.encodePacked("DDR ", Strings.toString(ddrTokenIds[i]) , " is already shared, revert execution.")));
        }
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            _isSharedDDR[ddrTokenIds[i]][patientDID] = true;
        }

        emit ApprovalShareDDR(tempPatient.owner(), ddrTokenIds);
        erc20Proxy.awardToken(tempPatient.owner(), ddrTokenIds.length);
    }

    
    // "disclosureConsentDDR" only use by Patient
    function disclosureConsentDDR(uint256[] memory ddrTokenIds, address providerDID) public onlyPatient {
        // check if token is consented
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            require(_isSharedDDR[ddrTokenIds[i]][msg.sender], "DDR is not shared!");
            require(_isConsentedDDR[ddrTokenIds[i]][providerDID] != true, string(abi.encodePacked("DDR ", Strings.toString(ddrTokenIds[i]) , " is already consent, revert execution.")));
        }
        for (uint i=0; i < ddrTokenIds.length; i++) {
            _isConsentedDDR[ddrTokenIds[i]][providerDID] = true;
            _listDDRTokenIdOfProvider[providerDID].push(ddrTokenIds[i]);
            _didConsentedOf[ddrTokenIds[i]].push(providerDID);
        }
        emit ApprovalDisclosureConsentDDR(msg.sender, providerDID, ddrTokenIds);
        erc20Proxy.awardToken(tx.origin, ddrTokenIds.length);
    }
}
