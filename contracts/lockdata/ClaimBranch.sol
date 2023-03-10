// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../DID/ClaimHolder.sol";
import "../interface/IClaim.sol";
import "../interface/IMerkleTreeBase.sol";

contract ClaimBranch is ERC721Base, IClaim {
    // Assign mapping
    mapping(uint256 => address) private _claimOfTokenIds;
    mapping(address => bytes32) private _claimHash;
    mapping(address => bool) private _isClaimMint;
    mapping(bytes32 => uint256) private _claimHashedId;
    mapping(uint256 => mapping( address => bytes32)) _hashClaimOfToken;
    uint256[] private _listTokenClaim;
    bytes32[] private _listHashValue;
    address[] private _listAddressOfClaim;
    mapping(uint256 => bool) _isClaimLocked;
    address public claimIssuer;

    // claimLock part
    constructor(address _claimHolder, address _authAddress)
        ERC721Base("Claim Branch Lock", "Claim LV2", _authAddress)
    {
        claimIssuer = _claimHolder;
    }

    function setTokenInfo(
        uint256 tokenId,
        bytes32 newHashValue,
        address accountDID
    ) internal {
        _claimOfTokenIds[tokenId] = accountDID;
        _hashClaimOfToken[tokenId][accountDID] = newHashValue;
        _claimHash[accountDID] = newHashValue;
        _listHashValue.push(newHashValue);
        _isClaimLocked[tokenId] = true;
        emit ClaimLockTokenMinted(tokenId, accountDID, newHashValue);
        emit ClaimTokenLocked(tokenId);
    }

    function getHashClaim(address accountDID) public view returns (bytes32) {
        ClaimHolder claimHolder = ClaimHolder(accountDID);
        string[] memory claimKey = claimHolder.getClaimsKeyOwnedByIssuer(
            claimIssuer
        );
        bytes32[] memory listHashDataClaim = new bytes32[](claimKey.length);
        for (uint256 i = 0; i < claimKey.length; i++) {
            bytes32 _claimId = keccak256(
                abi.encodePacked(claimIssuer, claimKey[i])
            );
            listHashDataClaim[i] = claimHolder.getHashClaim(_claimId);
        }
        bytes32 hashDataclaim = keccak256(abi.encodePacked(listHashDataClaim));
        return hashDataclaim;
    }

    //// This function only call when "Project manager" want to end the project and lock "ALL" data
    //// Because of that, mint = lock now, this function limited to onlyOwner (Project manager)
    function mint(
        address accountDID,
        string memory accountId,
        string memory uri
    ) public onlyOwner returns (uint256) {
        require(bytes(accountId).length > 0, "claim ID is empty!");
        require(
            _IAuth.checkAuth(ClaimHolder(accountDID), "ACCOUNT_ID", accountId),
            "Account Id is not valid!"
        );
        bytes32 hashDataclaim = getHashClaim(accountDID);
        uint256 tokenId = super.mint(uri);
        bytes32 newHashValue = keccak256(
            abi.encodePacked(accountDID, accountId, tokenId, hashDataclaim)
        );
        if (_isClaimMint[accountDID] == false) {
            _listAddressOfClaim.push(accountDID);
            _isClaimMint[accountDID] = true;
        }
        _listTokenClaim.push(tokenId);
        setTokenInfo(tokenId, newHashValue, accountDID);

        return tokenId;
    }

    function isLockedClaim(uint256 tokenId) public view returns (bool) {
        return _isClaimLocked[tokenId];
    }

    function getListHashValue() public view returns (bytes32[] memory) {
        return _listHashValue;
    }

    function getHashClaimOfToken(uint256 tokenId, address accountDID) public view returns (bytes32) {
        return _hashClaimOfToken[tokenId][accountDID];
    }

    function getClaimAddressOf(uint256 tokenId) public view returns (address) {
        return _claimOfTokenIds[tokenId];
    }

    function getListTokenIdClaim() public view returns (uint256[] memory) {
        return _listTokenClaim;
    }

    function getHashValueClaim(address accountDID)
        public
        view
        returns (bytes32)
    {
        return _claimHash[accountDID];
    }

    function getListAddressOfClaim() public view returns (address[] memory) {
        return _listAddressOfClaim;
    }
}
