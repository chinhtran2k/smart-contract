// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../interface/IDDR.sol";

contract DDR is ERC721Base, IDDR {
    mapping(address => bytes32) public _ddrHashPatient;
    mapping(address => bytes32) public _ddrHashPharmacy;
    mapping(uint256 => bool) private _isDDRLocked;
    mapping(uint256 => mapping(address => bool)) private _isDisclosable;
    mapping(uint256 => address) private _patient;
    mapping(address => bytes32[]) private _listDDRHashValueOfPatient;
    mapping(address => bytes32[]) private _listDDRHashValueOfPharmacy;
    bytes32 private _hashValuePatient;
    bytes32 private _hashValuePharmacy;

    modifier _valiDDRList(uint256 ddrId, address senderAddress) {
        require(!_isDDRLocked[ddrId], "ddr is already locked");
        require(ownerOf(ddrId) == senderAddress, "Not owner of ddr");
        _;
    }

    constructor(address _authAddress)
        ERC721Base("Drug Dispense Report", "DDR", _authAddress)
    {}

    function mint(
        bytes32 hashValue,
        string memory uri,
        address identity
    ) public onlyPharmacy returns (uint256) {
        uint256 tokenId = super.mint(uri);
        _patient[tokenId] = identity;
        _listDDRHashValueOfPatient[identity].push(hashValue);
        bytes32[] memory listDDRPatient = _listDDRHashValueOfPatient[identity];
        require(listDDRPatient.length != 0,"ddr of patient not create");
        if(listDDRPatient.length == 1){
            _hashValuePatient = listDDRPatient[0];
        }
        else{
            _hashValuePatient = listDDRPatient[0];
            for(uint256 i = 1; i < listDDRPatient.length; i++){
                _hashValuePatient = keccak256(abi.encodePacked(_hashValuePatient, listDDRPatient[i]));
            }
        }
        _ddrHashPatient[identity] = _hashValuePatient;

        _listDDRHashValueOfPharmacy[msg.sender].push(hashValue);
        bytes32[] memory listDDRPharmacy = _listDDRHashValueOfPharmacy[msg.sender];
        require(listDDRPharmacy.length != 0,"ddr of pharmacy not create");
        if(listDDRPharmacy.length == 1){
            _hashValuePharmacy = listDDRPharmacy[0];
        }
        else{
            _hashValuePharmacy = listDDRPharmacy[0];
            for(uint256 i = 1; i < listDDRPharmacy.length; i++){
                _hashValuePharmacy = keccak256(abi.encodePacked(_hashValuePharmacy, listDDRPharmacy[i]));
            }
        }
        _ddrHashPharmacy[msg.sender] = _hashValuePharmacy;
        _isDisclosable[tokenId][identity] = true;
        emit approval(identity, tokenId);
        _isDDRLocked[tokenId -1] = true;
        return tokenId;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _patient[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function statusLockDDR(uint256 tokenId) public view returns (bool) {
        return _isDDRLocked[tokenId];
    }

    function getShareApproval(uint256 ddrTokenId, address identity)
        external
        view
        override
        returns (bool)
    {
        return _isDisclosable[ddrTokenId][identity];
    }
}
