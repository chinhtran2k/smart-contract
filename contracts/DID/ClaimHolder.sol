// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC735.sol';
import './KeyHolder.sol';

contract ClaimHolder is KeyHolder, ERC735 {

    mapping (bytes32 => Claim) claims;
    mapping (string => bytes32[]) claimsByKey;

    mapping (string => bool) hasClaim;
    string[] public claimsKeyOwned;

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

        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 3), "Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != _issuer) {
            claimsByKey[_claimKey].push(claimId);
        }

        if (!hasClaim[_claimKey]) {
            hasClaim[_claimKey] = true;
            claimsKeyOwned.push(_claimKey);
        }

        claims[claimId].claimKey = _claimKey;
        claims[claimId].scheme = _scheme;
        claims[claimId].issuer = _issuer;
        claims[claimId].signature = _signature;
        claims[claimId].data = _data;
        claims[claimId].uri = _uri;

        emit ClaimAdded(
            claimId,
            _claimKey,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );

        return claimId;
    }

    function removeClaim(bytes32 _claimId) public override returns (bool success) {
        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        /* uint index; */
        /* (index, ) = claimsByType[claims[_claimId].claimKey].indexOf(_claimId);
        claimsByType[claims[_claimId].claimKey].removeByIndex(index); */

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

    function getClaimsKeyOwned() public view returns (string[] memory) {
        return claimsKeyOwned;
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
            string memory uri
        )
    {
        return (
            claims[_claimId].claimKey,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );
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
