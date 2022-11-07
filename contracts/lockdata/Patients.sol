// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";


contract Patient is ERC721Base{
  mapping(uint256 => bytes32) private _pharmacyHash;
  mapping(uint256 => uint256[]) private _ddrOfRecords;
  // Prescription private _prescription;
  mapping(uint256 => bytes32) private _ddrHash;
  mapping(uint256 => address) private _Patient;
  DDR public _DDR;
  constructor(address _prescriptionAddress, address _authAddress)
    ERC721Base("Health Record", "HR", _authAddress)
  {
    _DDR = DDR(_prescriptionAddress);
  }
 
  function mint(bytes32 hashValue, string memory uri, address _identity) public returns(uint256){
      uint256 tokenId = super.mint(uri);
      _pharmacyHash[tokenId] = hashValue;
      _Patient[tokenId] = _identity;
    return tokenId;
  }

  function getAddress(uint256 tokenId) public view returns (address){
    return _Patient[tokenId];
  }

  function getDDRofPatient(address _identity) public view returns(bytes32){
    return _DDR.getDDRofPatient(_identity);
  }
}

