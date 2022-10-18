// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";


contract healthRecords is ERC721Base{
  mapping(uint256 => byte32) private _healthRecordsHash;
  mapping(uint256 => byte32) private _PrescriptionOfRecords;

  // constructor(address _)

  

  function mint(byte32 hashValue, string memory uri, string memory data, uint256[] memory listId) public onlyClinic returns(uint256){
    require(keccak256(abi.encodePacked(data)) == hashValue, "Data Integrity fail");
    uint256 tokenId = super.mint(uri);
    _healthRecordsHash[tokenId] = hashValue;
    _PrescriptionOfRecords[tokenId] = listId;
    return tokenId;
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

