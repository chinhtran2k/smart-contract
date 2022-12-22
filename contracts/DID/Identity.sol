// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ClaimHolder.sol';


contract Identity is ClaimHolder {

    constructor(
        string[] memory _claimKey,
        uint256[] memory _scheme,
        address[] memory _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri,
        uint256[] memory _sigSizes,
        uint256[] memory dataSizes,
        uint256[] memory uriSizes
    ) ClaimHolder() {

        bytes32 claimId;
        uint offset = 0;
        uint uoffset = 0;
        uint doffset = 0;

        for (uint i = 0; i < _claimKey.length; i++) {

            claimId = keccak256(abi.encodePacked(_issuer[i], _claimKey[i]));

            claims[claimId] = Claim(
                _claimKey[i],
                _scheme[i],
                _issuer[i],
                getBytes(_signature, offset, _sigSizes[i]),
                getBytes(_data, doffset, dataSizes[i]),
                getString(_uri, uoffset, uriSizes[i])
            );
            claimsByKey[_claimKey[i]].push(claimId);
            if (!hasClaim[_claimKey[i]]) {
                hasClaim[_claimKey[i]] = true;
                claimsKeyOwnedByIssuer[_issuer[i]].push(_claimKey[i]);
            }
            offset += _sigSizes[i];
            uoffset += uriSizes[i];
            doffset += dataSizes[i];

            emit ClaimAdded(
                claimId,
                claims[claimId].claimKey,
                claims[claimId].scheme,
                claims[claimId].issuer,
                claims[claimId].signature,
                claims[claimId].data,
                claims[claimId].uri
            );
        }
    }

    function getBytes(bytes memory _str, uint256 _offset, uint256 _length) public pure returns (bytes memory ) {
        bytes memory sig = new bytes(_length);
        uint256 j = 0;
        for (uint256 k = _offset; k< _offset + _length; k++) {
          sig[j] = _str[k];
          j++;
        }
        return sig;
    }

    function getString(string memory _str, uint256 _offset, uint256 _length) public pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory sig = new bytes(_length);
        uint256 j = 0;
        for (uint256 k = _offset; k< _offset + _length; k++) {
          sig[j] = strBytes[k];
          j++;
        }
        return string(sig);
    }
}
