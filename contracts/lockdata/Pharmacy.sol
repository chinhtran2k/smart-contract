// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";

contract Pharmacy is ERC721Base {
    mapping(uint256 => bytes32) private _pharmacyHash;
    address private ddrAddress;
    mapping(uint256 => bytes32) private _ddrHash;
    mapping(uint256 => address) private _pharmacy;

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("Pharmacy", "PM", _authAddress)
    {
        ddrAddress = _ddrAddress;
    }

    function mint(
        bytes32 hashValue,
        string memory uri,
        address pharmacyAddress
    ) public returns (uint256) {
        uint256 tokenId = super.mint(uri);
        _pharmacyHash[tokenId] = hashValue;
        _pharmacy[tokenId] = pharmacyAddress;
        return tokenId;
    }

    function getHashValuePharmacy(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return _pharmacyHash[tokenId];
    }

    function getHashValueFromDDR(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return IDDR(ddrAddress).getHashValue(tokenId);
    }
}
