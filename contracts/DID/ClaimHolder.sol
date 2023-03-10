// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC735.sol';
import './KeyHolder.sol';

contract ClaimHolder is KeyHolder, ERC735 {

    mapping (bytes32 => Claim) claims;
    mapping (string => bytes32[]) claimsByKey;

    mapping (string => bool) hasClaim;
    mapping (address => string[]) public claimsKeyOwnedByIssuer;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addClaim(
        string memory _claimKey,
        uint256 _scheme,
        address _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
        public
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encodePacked(_issuer, _claimKey));
        bytes32 _hashClaim = getHashClaim(claimId);

        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 3), "Sender does not have claim signer key");
        }

        if (!hasClaim[_claimKey]) {
            claimsByKey[_claimKey].push(claimId);
        }

        if (!hasClaim[_claimKey]) {
            hasClaim[_claimKey] = true;
            claimsKeyOwnedByIssuer[_issuer].push(_claimKey);
        }

        claims[claimId].claimKey = _claimKey;
        claims[claimId].scheme = _scheme;
        claims[claimId].issuer = _issuer;
        claims[claimId].signature = _signature;
        claims[claimId].data = _data;
        claims[claimId].uri = _uri;
        claims[claimId].hashClaim = _hashClaim;

        emit ClaimAdded(
            claimId,
            _claimKey,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri,
            _hashClaim
        );

        return claimId;
    }

    function removeClaim(bytes32 _claimId) public override returns (bool success) {
        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }
        address _issuer = claims[_claimId].issuer;
        string memory _claimKey = claims[_claimId].claimKey;

        // Remove claimsKey
        for(uint256 i = 0; i < claimsKeyOwnedByIssuer[_issuer].length; i++){
            if(keccak256(abi.encodePacked(claimsKeyOwnedByIssuer[_issuer][i])) == keccak256(abi.encodePacked(_claimKey))){
                claimsKeyOwnedByIssuer[_issuer][i] = claimsKeyOwnedByIssuer[_issuer][claimsKeyOwnedByIssuer[_issuer].length - 1];
                break;
            }
        }
        claimsKeyOwnedByIssuer[_issuer].pop();

        // Remove claimsByKey
        for (uint256 i = 0; i < claimsByKey[_claimKey].length; i++) {
            if (claimsByKey[_claimKey][i] == _claimId) {
                claimsByKey[_claimKey][i] = claimsByKey[_claimKey][claimsByKey[_claimKey].length -1] ;
                break;
            }
        }
        claimsByKey[_claimKey].pop();


        emit ClaimRemoved(
            _claimId,
            claims[_claimId].claimKey,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );

        delete claims[_claimId];
        return true;
    }

    function getClaimsKeyOwnedByIssuer(address _issuer) public view returns (string[] memory) {
        return claimsKeyOwnedByIssuer[_issuer];
    }

    function getClaim(bytes32 _claimId)
        public
        override
        view
        returns(
            string memory claimKey,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri,
            bytes32 hashClaim
        )
    {
        return (
            claims[_claimId].claimKey,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri,
            claims[_claimId].hashClaim
        );
    }

    function getHashClaim(bytes32 _claimId)
        public   
        view
        returns(bytes32 hashClaim)
    {
        hashClaim = keccak256( abi.encodePacked(
                    claims[_claimId].claimKey,
                    claims[_claimId].scheme,
                    claims[_claimId].issuer,
                    claims[_claimId].signature,
                    claims[_claimId].data,
                    claims[_claimId].uri
                )
            );
        return hashClaim;
    }

    function getClaimIdsByKey(string memory _claimKey)
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return claimsByKey[_claimKey];
    }

}
