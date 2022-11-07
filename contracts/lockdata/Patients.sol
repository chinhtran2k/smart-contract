// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";
import "../interface/IPatients.sol";



contract Patients is ERC721Base, IPatients{
  event SetLockPatients(uint256[] _listIds, address _address);
  mapping(uint256 => bytes32) private _PatientsHash;
  mapping(uint256 => uint256[]) _patientsHistory;
  mapping(uint256 => bool) private _isPatientsHistory;
  mapping(uint256 => bool) private _isPatientsLocked;
  mapping(uint256 => uint256[]) private _DDROfPatients;
  address private DDRAddress;
  // Prescription private _prescription;
  mapping(uint256 => bytes32) private _DDRHash;

  modifier _validPatientsList(
    uint256[] memory PatientsIds, 
    address senderAddress
  ){
    for(uint256 i =0; i < PatientsIds.length; i++){
      require(!_isPatientsLocked[PatientsIds[i]],
      "Patient is already locked"
    );
    require(ownerOf(PatientsIds[i]) == senderAddress,
      "Not owner of Patient"
    );
    require(!_isPatientsHistory[PatientsIds[i]],
      "Cannot lock Patient History"
    );
    }
    _;
  }

  constructor(address _DDRAddress, address _authAddress)
    ERC721Base("Patients", "PT", _authAddress)
  {
    // _prescription = Prescription(prescription);
    DDRAddress = _DDRAddress;
  }

  function mint(bytes32 hashValue, string memory uri, uint256[] memory listId) public returns(uint256){
      uint256 tokenId = super.mint(uri);
      _PatientsHash[tokenId] = hashValue;
      _DDROfPatients[tokenId] = listId;
      IDDR(DDRAddress).setLockDDR(listId, msg.sender);
    return tokenId;
  }

  // function discloseApproval(address _authAddress, uint256 tokenId) external override {
  //   address owner = ERC721.ownerOf(tokenId);
  //   require(_authAddress != owner, "ERC721: approval to current owner");
  //   // _prescription.discloseApproval(tokenId, _authAddress);
  //   // IPrescription(prescriptionAddress).discloseApproval(tokenId, _authAddress);
  // } 

  function setLockPatients(uint256[] memory PatientsIds, address senderAddress) external override _validPatientsList(PatientsIds, senderAddress) {
        for (uint256 i = 0; i < PatientsIds.length; i++) {
            _isPatientsLocked[PatientsIds[i]] = true;
        }
        emit SetLockPatients(PatientsIds, senderAddress);
    }

  
  function checkDataIntegrity(uint256 PatientsId, bytes32 hashValue)
        public
        view
        returns (bool, uint256[] memory)
    {
        return (
            _PatientsHash[PatientsId] == hashValue,
            _DDROfPatients[PatientsId]
        );
    }
  function getHashValueFromDDR(uint256 tokenId) public view returns(bytes32){
      return IDDR(DDRAddress).getHashValue(tokenId);
  }

  function getHashValue(uint256 tokenId) external view override returns(bytes32){
        return _PatientsHash[tokenId]; 
  }
}

