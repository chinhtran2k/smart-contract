// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./Prescription.sol";


contract healthRecords is ERC721Base{
  mapping(uint256 => bytes32) private _healthRecordsHash;
  mapping(uint256 => uint256[]) private _PrescriptionOfRecords;
  Prescription private _prescription;

  constructor(address prescription, address authenticatior)
    ERC721Base("Health Record", "HR", authenticatior)
  {
    _prescription = Prescription(prescription);
  }
 
  function mint(bytes32 hashValue, string memory uri, string memory data, uint256[] memory listId) public returns(uint256){
      require(keccak256(abi.encodePacked(data)) == hashValue, "Data Integrity fail");
      uint256 tokenId = super.mint(uri);
      _healthRecordsHash[tokenId] = hashValue;
      _PrescriptionOfRecords[tokenId] = listId;
    return tokenId;
  }

  function discloseApproval(address _authAddress, uint256 tokenId) public virtual {
    address owner = ERC721.ownerOf(tokenId);
    require(_authAddress != owner, "ERC721: approval to current owner");

    // require(
    //     _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
    //     "ERC721: approve caller is not token owner or approved for all"
    // );

    _prescription.discloseApproval(tokenId, _authAddress);
  } 



  function checkDataIntegrity(uint256 healthRecordId, bytes32 hashValue)
        public
        view
        returns (bool, uint256[] memory)
    {
        return (
            _healthRecordsHash[healthRecordId] == hashValue,
            _PrescriptionOfRecords[healthRecordId]
        );
    }
}

