// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";


contract Pharmacy is ERC721Base{
  mapping(uint256 => bytes32) private _pharmacyHash;
  mapping(uint256 => uint256[]) private _ddrOfPharmacy;
  address private ddrAddress;
  mapping(uint256 => bytes32) private _ddrHash;

  constructor(address _ddrAddress, address _authAddress)
    ERC721Base("Health Record", "HR", _authAddress)
  {
    ddrAddress = _ddrAddress;
  }
 
  function mint(bytes32 hashValue, string memory uri, string memory data, uint256[] memory listId) public returns(uint256){
      require(keccak256(abi.encodePacked(data)) == hashValue, "Data Integrity fail");
      uint256 tokenId = super.mint(uri);
      _pharmacyHash[tokenId] = hashValue;
      _ddrOfPharmacy[tokenId] = listId;
      IDDR(ddrAddress).setLockDDR(listId, msg.sender);
    return tokenId;
  }

  function discloseApproval(address _authAddress, uint256 tokenId) public virtual {
    address owner = ERC721.ownerOf(tokenId);
    require(_authAddress != owner, "ERC721: approval to current owner");

  } 



  function checkDataIntegrity(uint256 healthRecordId, bytes32 hashValue)
        public
        view
        returns (bool, uint256[] memory)
    {
        return (
            _pharmacyHash[healthRecordId] == hashValue,
            _ddrOfPharmacy[healthRecordId]
        );
    }
  function getHashValueFromPrescription(uint256 tokenId) public view returns(bytes32){
      return IDDR(ddrAddress).getHashValue(tokenId);

  }
}

