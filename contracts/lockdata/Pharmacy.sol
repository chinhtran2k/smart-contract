// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IPatients.sol";


contract Pharmacy is ERC721Base{
  mapping(uint256 => bytes32) private _PharmacyHash;
  mapping(uint256 => uint256[]) private _PatientsOfPharmacy;
  address private PatientsAddress;
  mapping(uint256 => bytes32) private _PatientsHash;

  constructor(address _PatientsAddress, address _authAddress)
    ERC721Base("Pharmacy", "PM", _authAddress)
  {
    PatientsAddress = _PatientsAddress;
  }
  
  function mint(bytes32 hashValue, string memory uri, string memory data, uint256[] memory listId) public returns(uint256){
      require(keccak256(abi.encodePacked(data)) == hashValue, "Data Integrity fail");
      uint256 tokenId = super.mint(uri);
      _PharmacyHash[tokenId] = hashValue;
      _PatientsOfPharmacy[tokenId] = listId;
      // IPatients(PatientsAddress).setLockPatients(listId, msg.sender);
    return tokenId;
  }

  function discloseApproval(address _authAddress, uint256 tokenId) public virtual {
    address owner = ERC721.ownerOf(tokenId);
    require(_authAddress != owner, "ERC721: approval to current owner");

    // _prescription.discloseApproval(tokenId, _authAddress);
    // IPrescription(prescriptionAddress).discloseApproval(tokenId, _authAddress);
  } 

  function checkDataIntegrity(uint256 PharmacyId, bytes32 hashValue)
        public
        view
        returns (bool, uint256[] memory)
    {
        return (
            _PharmacyHash[PharmacyId] == hashValue,
            _PatientsOfPharmacy[PharmacyId]
        );
    }
  function getHashValueFromPatients(uint256 tokenId) public view returns(bytes32){
      return IPatients(PatientsAddress).getHashValue(tokenId);

  }
}

