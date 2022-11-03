// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../interface/IDDR.sol";

 contract DDR is ERC721Base, IDDR {
  mapping(uint256 => uint256[]) private _ddrHistory;
  mapping(uint256 => bytes32) public _ddrHash;
  mapping(uint256 => bool) private _isDDRHistory;
  mapping(uint256 => bool) private _isDDRLocked;
  mapping(uint256 => mapping(address => bool))  private _isDisclosable;
  mapping(address => bytes32) private _DDRPatient;
  address private phamacyContractAddress;
  bytes32 private _hashValue;

  modifier _valiDDRList(
        uint256[] memory ddrIds,
        address senderAddress
    ) {
        for (uint256 i = 0; i < ddrIds.length; i++) {
            require(
                !_isDDRLocked[ddrIds[i]],
                "ddr is already locked"
            );
            require(
                ownerOf(ddrIds[i]) == senderAddress,
                "Not owner of ddr"
            );
            require(
                !_isDDRHistory[ddrIds[i]],
                "Cannot lock ddr History"
            );
        }
        _;
    }

    constructor(address _authAddress)
        ERC721Base("Prescription", "PS", _authAddress)
    {}
  
    function mint(
        bytes32 hashValue,
        string memory uri,
        string memory data,
        address identity
    ) public onlyPharmacy returns (uint256) {
        require(
            keccak256(abi.encodePacked(data)) == hashValue,
            "Data Integrity fail"
        );
        _hashValue = keccak256(abi.encodePacked(_hashValue , hashValue));
        uint256 tokenId = super.mint(uri);
        _ddrHash[tokenId] = _hashValue;
        _ddrHistory[tokenId].push(tokenId);
        _DDRPatient[identity] = _hashValue;
        _isDDRHistory[tokenId] = false;
        return tokenId;
    }

    function updatePrescription(
        uint256 ddrId,
        bytes32 hashValue,
        string memory uri,
        string memory data
    ) public onlyPharmacy {
        require(
            !_isDDRHistory[ddrId],
            "Cannot update Prescription History"
        );

        require(!_isDDRLocked[ddrId], "Prescription is locked");

        require(
            ownerOf(ddrId) == _msgSender(),
            "Not the owner of the Prescription"
        );

        require(
            keccak256(abi.encodePacked(data)) == hashValue,
            "Data integrity failure"
        );

        uint256 newddrId = super.mint(uri);
        _ddrHash[newddrId] = hashValue;
        _ddrHistory[newddrId].push(newddrId);
        _isDDRHistory[newddrId] = true;

        _ddrHistory[ddrId].push(newddrId);
    }

    function getDDRHistory(uint256 ddrId)
        public
        view
        returns (uint256[] memory)
    {
        return _ddrHistory[ddrId];
    }

    function getDDRofPatient (address _identity) public view returns(bytes32){
        return _DDRPatient[_identity];
    }

    function checkDataIntegrity(uint256 ddrId, bytes32 hashValue)
        public
        view
        returns (bool)
    {
        uint256 lastddrId = _ddrHistory[ddrId][
            _ddrHistory[ddrId].length - 1
        ];

        return _ddrHash[lastddrId] == hashValue;
    }

    function setLockDDR(
        uint256[] memory ddrIds,
        address senderAddress
    ) external override _valiDDRList(ddrIds, senderAddress) {
        for (uint256 i = 0; i < ddrIds.length; i++) {
            _isDDRLocked[ddrIds[i]] = true;
        }
    }

    function discloseApproval(uint256 ddrId, address _address) external override onlyPharmacy{
        _isDisclosable[ddrId][_address] = true;
    }

    function getDiscloseApproval(uint256 ddrId, address _address) external view override  onlyPharmacy returns(bool){
        return _isDisclosable[ddrId][_address];
    }

    function getHashValue(uint256 tokenId) external view override returns(bytes32){
        return _ddrHash[tokenId]; 
    }
}