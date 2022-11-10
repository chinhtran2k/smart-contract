// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";

contract Pharmacy is ERC721Base {
    mapping(address => bytes32) private _pharmacyHashValue;
    mapping(uint256 => bytes32) private _pharmacyHash;
    mapping(uint256 => bytes32) private _ddrHash;
    mapping(uint256 => address) private _pharmacy;
    bytes32 private _hashValue;
    DDR public _DDR;

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("Pharmacy", "PM", _authAddress)
    {
    _DDR = DDR(_ddrAddress);
    }

    function mint(address pharmacyAddress, string memory uri) public onlyPharmacy returns(uint256){
      uint256 tokenId = super.mint(uri);
      _hashValue = _DDR._ddrHashPharmacy(pharmacyAddress);
      _pharmacyHashValue[pharmacyAddress] = _hashValue;
      _pharmacyHash[tokenId] = _hashValue;
      _pharmacy[tokenId] = pharmacyAddress;

    return tokenId;
     }

    function getAddressPharmacy(uint256 tokenId) public view returns (address) {
        return _pharmacy[tokenId];
    }

    function getHashPharmacy(uint256 tokenId) public view returns(bytes32){
      return _pharmacyHash[tokenId];
    }

    function getHashValuePharmacy(address pharmacy) public view returns(bytes32){
      return _pharmacyHashValue[pharmacy];
    }
}
