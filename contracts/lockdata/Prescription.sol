// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "../utils/ERC721Base.sol";
import "../interface/IPrescription.sol";

 contract Prescription is ERC721Base, IPrescription {
  mapping(uint256 => uint256[]) private _PrescriptionHistory;
  mapping(uint256 => bytes32) public _PrescriptionHash;
  mapping(uint256 => bool) private _isPrescriptionHistory;
  mapping(uint256 => bool) private _isPrescriptionLocked;
  mapping(uint256 => mapping(address => bool))  private _isDisclosable;

  address private healthRecordContractAddress;
  

  modifier _validPrescriptionList(
        uint256[] memory PrescriptionIds,
        address senderAddress
    ) {
        for (uint256 i = 0; i < PrescriptionIds.length; i++) {
            require(
                !_isPrescriptionLocked[PrescriptionIds[i]],
                "Prescription is already locked"
            );
            require(
                ownerOf(PrescriptionIds[i]) == senderAddress,
                "Not owner of Prescription"
            );
            require(
                !_isPrescriptionHistory[PrescriptionIds[i]],
                "Cannot lock Prescription History"
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
        string memory data
    ) public returns (uint256) {
        require(
            keccak256(abi.encodePacked(data)) == hashValue,
            "Data Integrity fail"
        );
        uint256 tokenId = super.mint(uri);
        _PrescriptionHash[tokenId] = hashValue;
        _PrescriptionHistory[tokenId].push(tokenId);
        _isPrescriptionHistory[tokenId] = false;

        return tokenId;
    }

    function updatePrescription(
        uint256 PrescriptionId,
        bytes32 hashValue,
        string memory uri,
        string memory data
    ) public {
        require(
            !_isPrescriptionHistory[PrescriptionId],
            "Cannot update Prescription History"
        );

        require(!_isPrescriptionLocked[PrescriptionId], "Prescription is locked");

        require(
            ownerOf(PrescriptionId) == _msgSender(),
            "Not the owner of the Prescription"
        );

        require(
            keccak256(abi.encodePacked(data)) == hashValue,
            "Data integrity failure"
        );

        uint256 newPrescriptionId = super.mint(uri);
        _PrescriptionHash[newPrescriptionId] = hashValue;
        _PrescriptionHistory[newPrescriptionId].push(newPrescriptionId);
        _isPrescriptionHistory[newPrescriptionId] = true;

        _PrescriptionHistory[PrescriptionId].push(newPrescriptionId);
    }

    function getPrescriptionHistory(uint256 PrescriptionId)
        public
        view
        returns (uint256[] memory)
    {
        return _PrescriptionHistory[PrescriptionId];
    }

    function checkDataIntegrity(uint256 PrescriptionId, bytes32 hashValue)
        public
        view
        returns (bool)
    {
        uint256 lastPrescriptionId = _PrescriptionHistory[PrescriptionId][
            _PrescriptionHistory[PrescriptionId].length - 1
        ];

        return _PrescriptionHash[lastPrescriptionId] == hashValue;
    }

    function setLockPrescription(
        uint256[] memory PrescriptionIds,
        address senderAddress
    ) external override _validPrescriptionList(PrescriptionIds, senderAddress) {
        for (uint256 i = 0; i < PrescriptionIds.length; i++) {
            _isPrescriptionLocked[PrescriptionIds[i]] = true;
        }
    }

    function setHealthRecordAddress(address _address) external override onlyHealthRecordAddress {
        healthRecordContractAddress = _address;
    } 

    function getHealthRecordAddress() external view override returns(address){
        return healthRecordContractAddress;
    }

    function discloseApproval(uint256 prescriptionId, address _address) external override onlyHealthRecordAddress{
        _isDisclosable[prescriptionId][_address] = true;
    }

    function getDiscloseApproval(uint256 prescriptionId, address _address) external view override returns(bool){
        return _isDisclosable[prescriptionId][_address];
    }

    modifier onlyHealthRecordAddress(){
        require(msg.sender == healthRecordContractAddress, "Only this healthRecordAddress can do this");
        _;
    }
    function getHashValue(uint256 tokenId) external view override returns(bytes32){
        return _PrescriptionHash[tokenId]; 
    }
}
