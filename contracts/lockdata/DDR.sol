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
    mapping(uint256 => mapping( address => bytes32)) private _ddrHash;

    mapping(uint256 => bool) private _isDDRLocked;
    mapping(uint256 => mapping(address => bool)) private _isSharedDDR;
    mapping(uint256 => mapping(address => bool)) private _isConsentedDDR;
    mapping(uint256 => address) private _patient;
    mapping(uint256 => address[]) private _didConsentedOf;
    mapping(address => uint256[]) private _listDDRTokenIdOfPatient;
    mapping(address => mapping(address => uint256[]))
        private _listDDRTokenIdPatientOfProvider;
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
        ERC721Base("DDR Lock", "DDR", _authAddress)
    {
        claimHolder = ClaimHolder(_claimHolderAddress);
    }

    function getDDRHash(uint256 tokenId, address patientDID) public view returns (bytes32) {
        return _ddrHash[tokenId][patientDID];
    }

    function getTokenIdOfPatientDIDByRawId(
        address patientDID,
        string memory ddrId
    ) public view returns (uint256) {
        return _ddrHashedId[keccak256(abi.encodePacked(patientDID, ddrId))];
    }

    function getDDRHashOfPatientDIDByRawId(
        address patientDID,
        string memory ddrId
    ) public view returns (bytes32) {
        bytes32 hashedRawId = keccak256(abi.encodePacked(patientDID, ddrId));
        uint256 tokenId = _ddrHashedId[hashedRawId];
        return _ddrHash[tokenId][patientDID];
    }

    function getToken(uint256 tokenID)
        public
        view
        returns (
            uint256 tokenId,
            address patientDID,
            string memory ddrId,
            bytes32 hashValue
        )
    {
        return (
            tokenID,
            _patient[tokenID],
            _ddrId[tokenID],
            _ddrHash[tokenID][_patient[tokenID]]
        );
    }

    function setTokenInfo(
        uint256 tokenId,
        bytes32 hashValue,
        string memory ddrId,
        address patientDID
    ) internal {
        _patient[tokenId] = patientDID;
        bytes32 hashedRawId = keccak256(abi.encodePacked(patientDID, ddrId));
        // Create DDR hash value base on DID and hashed value
        require(
            _ddrHashedId[hashValue] == 0x00,
            "DDR mint error: DDRID exist!"
        );

        // Assign data to map
        _ddrHashedId[hashedRawId] = tokenId;
        _ddrHash[tokenId][patientDID] = hashValue;
        _patient[tokenId] = patientDID;
        _listDDRTokenIdOfPatient[patientDID].push(tokenId);
        _ddrId[tokenId] = ddrId;

        _isDDRLocked[tokenId - 1] = true;
    }

    function mint(
        bytes32 hashValue,
        string memory ddrId,
        string memory uri,
        address patientDID
    ) public onlyClaimHolder returns (uint256) {
        require(
            _IAuth.checkAuth(
                ClaimHolder(patientDID),
                "ACCOUNT_TYPE",
                "PATIENT"
            ),
            "Patient DID is not valid!"
        );
        require(bytes(ddrId).length > 0, "DDR ID is empty!");
        ClaimHolder patient = ClaimHolder(patientDID);

        uint256 tokenId = super.mintTo(patient.owner(), uri);
        setTokenInfo(tokenId, hashValue, ddrId, patientDID);

        emit MintedDDR(tokenId, ddrId, hashValue, patientDID);
        emit DDRTokenLocked(tokenId - 1);

        return tokenId;
    }

    function mintBatch(
        bytes32[] memory hashValues,
        string[] memory ddrIds,
        string[] memory uris,
        address patientDID
    ) public onlyClaimHolder returns (uint256[] memory) {
        require(
            hashValues.length == ddrIds.length,
            "DDR mint error: length of hashValue and ddrId is not equal!"
        );
        require(
            hashValues.length == uris.length,
            "DDR mint error: length of hashValue and uri is not equal!"
        );

        // check ddrId
        for (uint256 i = 0; i < ddrIds.length; i++) {
            require(bytes(ddrIds[i]).length > 0, "DDR ID is empty!");
        }

        // uint256[] memory tokenIds = new uint256[](hashValues.length);
        uint256[] memory tokenIds = mintBatchTo(patientDID, uris);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            setTokenInfo(tokenIds[i], hashValues[i], ddrIds[i], patientDID);
        }

        emit MintedBatchDDR(tokenIds, ddrIds, hashValues, patientDID);

        return tokenIds;
    }

    function setERC20Proxy(address _erc20Proxy) public onlyOwner {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
    }

    function getListDDRTokenIdOfPatient(address patientDID)
        public
        view
        returns (uint256[] memory)
    {
        return _listDDRTokenIdOfPatient[patientDID];
    }

    function getListDDRTokenIdOfProvider(
        address pateintDID,
        address providerDID
    ) public view returns (uint256[] memory) {
        return _listDDRTokenIdPatientOfProvider[providerDID][pateintDID];
    }

    function patientOf(uint256 tokenId) public view returns (address) {
        address _owner = _patient[tokenId];
        require(_owner != address(0), "ERC721: invalid token ID");
        return _owner;
    }

    //// Status part
    function isLockedDDR(uint256 tokenId) public view returns (bool) {
        return _isDDRLocked[tokenId];
    }

    function isSharedDDR(address identity, uint256 ddrTokenId)
        public
        view
        returns (bool)
    {
        return _isSharedDDR[ddrTokenId][identity];
    }

    function isConsentedDDR(address identity, uint256 ddrTokenId)
        public
        view
        returns (bool)
    {
        return _isConsentedDDR[ddrTokenId][identity];
    }

    function getDIDConsentedOf(uint256 tokenId)
        public
        view
        returns (address[] memory)
    {
        return _didConsentedOf[tokenId];
    }

    //// Approval part
    // "shareDDR" only use by ClaimHolder
    function shareDDR(uint256[] memory ddrTokenIds, address patientDID)
        public
        onlyClaimHolder
    {
        require(
            _IAuth.checkAuth(
                ClaimHolder(patientDID),
                "ACCOUNT_TYPE",
                "PATIENT"
            ),
            "Patient DID is not valid!"
        );
        ClaimHolder tempPatient = ClaimHolder(patientDID);

        uint256 ddrShareLength = ddrTokenIds.length;

        // check if token is shared
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            require(
                _ddrHash[ddrTokenIds[i]][patientDID] != 0x00,
                "tokenId not exist, revert transaction"
            );
            if (_isSharedDDR[ddrTokenIds[i]][patientDID] == true) {
                ddrShareLength--;
            }
        }
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            _isSharedDDR[ddrTokenIds[i]][patientDID] = true;
        }

        emit ApprovalShareDDR(tempPatient.owner(), ddrTokenIds);
        erc20Proxy.awardToken(tempPatient.owner(), ddrShareLength);
    }

    // "disclosureConsentDDR" only use by Patient
    function consentDisclosureDDR(
        uint256[] memory ddrTokenIds,
        address providerDID
    ) public onlyPatient {
        require(
            _IAuth.checkAuth(
                ClaimHolder(providerDID),
                "ACCOUNT_TYPE",
                "PROVIDER"
            ),
            "Patient DID is not valid!"
        );
        ClaimHolder tempPatient = ClaimHolder(address(msg.sender));

        uint256 ddrConsentLength = ddrTokenIds.length;

        // check if token is consented
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            require(
                _isSharedDDR[ddrTokenIds[i]][msg.sender],
                "DDR is not shared!"
            );
            if (_isConsentedDDR[ddrTokenIds[i]][providerDID] == true) {
                ddrConsentLength--;
            }
        }
        for (uint256 i = 0; i < ddrTokenIds.length; i++) {
            _isConsentedDDR[ddrTokenIds[i]][providerDID] = true;
            _listDDRTokenIdPatientOfProvider[providerDID][msg.sender].push(
                ddrTokenIds[i]
            );
            _didConsentedOf[ddrTokenIds[i]].push(providerDID);
        }
        emit ApprovalDisclosureConsentDDR(msg.sender, providerDID, ddrTokenIds);
        erc20Proxy.awardToken(tempPatient.owner(), ddrConsentLength);
    }
}
