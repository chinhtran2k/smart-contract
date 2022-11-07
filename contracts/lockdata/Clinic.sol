// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";


contract Clinic is ERC721Base{
  mapping(uint256 => bytes32) private _pharmacyHash;
  mapping(uint256 => uint256[]) private _ddrOfRecords;
  mapping(uint256 => bytes32) private _ddrHash;
  mapping(uint256 => address) private _Clinic;
  DDR public _DDR;
  constructor(address _ddrAddress, address _authAddress)
    ERC721Base("Health Record", "HR", _authAddress)
  {
    _DDR = DDR(_prescriptionAddress);
  }
 
  function mint(bytes32 hashValue, string memory uri, address _identity) public returns(uint256){
      uint256 tokenId = super.mint(uri);
      _pharmacyHash[tokenId] = hashValue;
      _Clinic[tokenId] = _identity;
    return tokenId;
  }

  function getAddress(uint256 tokenId) public view returns (address){
    return _Clinic[tokenId];
  }

  function getDDRofPatient(address _identity) public view returns(bytes32){
    return _DDR.getDDRofPatient(_identity);
  }
}

