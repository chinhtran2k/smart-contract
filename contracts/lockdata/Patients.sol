// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDR.sol";

contract Patient is ERC721Base {
    mapping(uint256 => address) private _Patient;
    mapping(uint256 => bytes32) private _PatientHashValue;
    DDR public _DDR;

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("Patient", "PT", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
    }

    function mint(
        bytes32 hashValue,
        string memory uri,
        address _identity
    ) public returns (uint256) {
        uint256 tokenId = super.mint(uri);
        _PatientHashValue[tokenId] = hashValue;
        _Patient[tokenId] = _identity;
        return tokenId;
    }

    function getAddress(uint256 tokenId) public view returns (address) {
        return _Patient[tokenId];
    }

    function getHashValuePatient(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return _PatientHashValue[tokenId];
    }

    function getDDRofPatient(address _identity) public view returns (bytes32) {
        return _DDR.getDDRofPatient(_identity);
    }
}
