// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";


contract Pharmacy is ERC721Base{
  mapping(uint256 => bytes32) private _pharmacyHash;
  // mapping(uint256 => uint256[]) private _ddrOfPharmacy;
  address private ddrAddress;
  mapping(uint256 => bytes32) private _ddrHash;
  mapping(uint256 => address) private _pharmacy;

  constructor(address _ddrAddress, address _authAddress)
    ERC721Base("Health Record", "HR", _authAddress)
  {
    ddrAddress = _ddrAddress;
  }
 
  function mint(bytes32 hashValue, string memory uri, address pharmacyAddress) public returns(uint256){
      uint256 tokenId = super.mint(uri);
      _pharmacyHash[tokenId] = hashValue;
      _pharmacy[tokenId] = pharmacyAddress;

    return tokenId;
  }

  function discloseApproval(address _authAddress, uint256 tokenId) public virtual {
    address owner = ERC721.ownerOf(tokenId);
    require(_authAddress != owner, "ERC721: approval to current owner");
  } 

  function getHashValueFromDDR(uint256 tokenId) public view returns(bytes32){
      return IDDR(ddrAddress).getHashValue(tokenId);

  }
}

