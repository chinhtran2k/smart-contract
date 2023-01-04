// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaim {
    event ClaimLockTokenMinted(uint256 tokenId, address claimDID, bytes32 hashValue);
    event ClaimTokenLocked(uint256 tokenId);
}