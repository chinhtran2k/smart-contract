// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../DID/ClaimHolder.sol";
import "../interface/IProvider.sol";
import "../interface/IMerkleTreeBase.sol";

contract Provider is ERC721Base, IProvider {
    // Assign mapping
    mapping(uint256 => address) private _providerOfTokenIds;
    mapping(address => uint256) private _tokenIdOfProvider;
    mapping(address => bytes32) private _ddrHash;
    mapping(address => bool) private _isProviderMint;
    mapping(bytes32 => uint256) private _providerHashedId;
    uint256[] private _listTokenProvider;
    bytes32[] private _listHashValue;
    address[] private _listAddressOfProvider;
    mapping(uint256 => bool) _isDDRLocked;
    address public claimIssuer;
    // ProviderLock part
    constructor(address _authAddress, address _claimHolder)
        ERC721Base("Provider Lock", "PR", _authAddress)
    {
        claimIssuer = _claimHolder;
    }

    function setTokenInfo(
            uint256 tokenId, 
            bytes32 newHashValue,
            address providerDID
        ) 
        internal
    {   
        _providerOfTokenIds[tokenId] = providerDID;
        _tokenIdOfProvider[providerDID] = tokenId;
        _ddrHash[providerDID] = newHashValue;
        _listHashValue.push(newHashValue);
        _isDDRLocked[tokenId] = true;
        emit ProviderLockTokenMinted(tokenId, providerDID, newHashValue);
        emit ProviderTokenLocked(tokenId);
    }

    function getHashClaim(address providerDID) public view returns(bytes32){
        ClaimHolder claimHolder = ClaimHolder(providerDID);
        uint256 scheme;
        address issuer;
        bytes memory signature;
        bytes memory data;
        string memory uri;
        string[] memory claimKey = claimHolder.getClaimsKeyOwnedByIssuer(claimIssuer);
        bytes32[] memory listHashDataProvider = new bytes32[](claimKey.length);
        for(uint256 i=0; i< claimKey.length; i++){
            bytes32 _claimId = keccak256(abi.encodePacked(claimIssuer, claimKey[i]));
            (claimKey[i], scheme, issuer, signature, data, uri) = claimHolder.getClaim(_claimId);
            listHashDataProvider[i] = keccak256(abi.encodePacked(claimKey[i], scheme, issuer, signature, data, uri));
        }
        bytes32 hashDataProvider = keccak256(abi.encodePacked(listHashDataProvider));
        return hashDataProvider;
    }

    //// This function only call when "Project manager" want to end the project and lock "ALL" data
    //// Because of that, mint = lock now, this function limited to onlyOwner (Project manager)
    function mint(address providerDID, string memory accountId, string memory uri) public onlyOwner returns(uint256){
        require(bytes(accountId).length > 0, "Provider ID is empty!");
        require(_IAuth.checkAuth(ClaimHolder(providerDID), "ACCOUNT_TYPE", "PROVIDER"), "Provider DID is not valid!");
        bytes32 hashDataProvider = getHashClaim(providerDID);
        bytes32 newHashValue = keccak256(abi.encodePacked(providerDID, accountId, hashDataProvider));
        uint256 tokenId = super.mint(uri);
        if(_isProviderMint[providerDID] == false){
            _listAddressOfProvider.push(providerDID);
            _isProviderMint[providerDID]==true;
        }
        _listTokenProvider.push(tokenId);
        setTokenInfo(tokenId, newHashValue, providerDID);

        return tokenId;
    }

    function isLockedProvider(uint256 tokenId) public view returns (bool) {
        return _isDDRLocked[tokenId];
    }

    function getListHashValue() public view returns(bytes32[] memory){
        return _listHashValue;
    }

    function getProviderAddressOf(uint256 tokenId) public view returns (address) {
        return _providerOfTokenIds[tokenId];
    }

    function getTokenIdOfProvider(address ProviderDID) public view returns (uint256) {
        return _tokenIdOfProvider[ProviderDID];
    }

    function getListTokenIdProvider() public view returns (uint256[] memory) {
        return _listTokenProvider;
    }
    
    function getHashValueProvider(address providerDID) public view returns(bytes32) {
        return _ddrHash[providerDID];
    }

    function getListAddressOfProvider() public view returns(address[] memory){
        return _listAddressOfProvider;
    }
}

