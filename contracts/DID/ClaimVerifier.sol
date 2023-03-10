// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ClaimHolder.sol';

contract ClaimVerifier {

  event ClaimValid(ClaimHolder _identity, string claimKey, string claimValue);
  event ClaimInvalid(ClaimHolder _identity, string claimKey, string claimValue);

  ClaimHolder public trustedClaimHolder;

  constructor(address _trustedClaimHolder) {
    trustedClaimHolder = ClaimHolder(_trustedClaimHolder);
  }

  function checkClaim(ClaimHolder _identity, string memory claimKey, string memory claimValue)
    public
    returns (bool claimValid)
  {
    if (claimIsValid(_identity, claimKey, claimValue)) {
      emit ClaimValid(_identity, claimKey, claimValue);
      return true;
    } else {
      emit ClaimInvalid(_identity, claimKey, claimValue);
      return false;
    }
  }

  function claimIsValid(ClaimHolder _identity, string memory claimKey, string memory claimValue)
    public
    view
    returns (bool claimValid)
  {
    string memory foundclaimKey;
    uint256 scheme;
    address issuer;
    bytes memory sig;
    bytes memory data;
    bytes32 hashClaim;
    string memory uri;
    // Construct claimId (identifier + claim type)
    bytes32 claimId = keccak256(abi.encodePacked(trustedClaimHolder, claimKey));

    // Fetch claim from user
    ( foundclaimKey, scheme, issuer, sig, data, uri, hashClaim) = _identity.getClaim(claimId);

    if (keccak256(data) != keccak256(bytes(claimValue))) {
      return false;
    }

    bytes32 dataHash = keccak256(abi.encodePacked(_identity, claimKey, data));
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

    // Recover address of data signer
    address recovered = getRecoveredAddress(sig, prefixedHash);

    // Take hash of recovered address
    bytes32 hashedAddr = keccak256(abi.encodePacked(recovered));

    // Does the trusted identifier have they key which signed the user's claim?
    return trustedClaimHolder.keyHasPurpose(hashedAddr, 3);
  }

  function getRecoveredAddress(bytes memory sig, bytes32 dataHash)
      public
      pure
      returns (address addr)
  {
      bytes32 ra;
      bytes32 sa;
      uint8 va;

      // Check the signature length
      require(sig.length == 65, "Signature not valid!");

      // Divide the signature in r, s and v variables
      assembly {
        ra := mload(add(sig, 32))
        sa := mload(add(sig, 64))
        va := byte(0, mload(add(sig, 96)))
      }

      if (va < 27) {
        va += 27;
      }

      address recoveredAddress = ecrecover(dataHash, va, ra, sa);

      return (recoveredAddress);
  }
}
