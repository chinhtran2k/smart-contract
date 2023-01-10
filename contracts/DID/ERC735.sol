// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ERC735 {

    event ClaimRequested(uint256 indexed claimRequestId, string indexed claimKey, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);    
    event ClaimAdded(bytes32 indexed claimId, string indexed claimKey, address indexed issuer, uint256 signatureType, bytes32 signature, bytes claim, string uri, bytes32 hashClaim);
    event ClaimAdded(bytes32 indexed claimId, string indexed claimKey, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri, bytes32 hashClaim);
    event ClaimRemoved(bytes32 indexed claimId, string indexed claimKey, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, string indexed claimKey, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Claim {
        string claimKey;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + claimKey + data
        bytes data;
        string uri;
        bytes32 hashClaim;
    }

    function getClaim(bytes32 _claimId) public virtual returns(string memory claimKey, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri, bytes32 hashClaim);
    function getClaimIdsByKey(string memory _claimKey) public virtual returns(bytes32[] memory claimIds);
    function addClaim(string memory _claimKey, uint256 _scheme, address issuer, bytes memory _signature, bytes memory _data, string memory _uri) public virtual returns (bytes32 claimRequestId);
    function removeClaim(bytes32 _claimId) public virtual returns (bool success);
}
