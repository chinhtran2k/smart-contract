// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaim {
    event claimLockTokenMinted(uint256 tokenId, address claimDID, bytes32 hashValue);
    event claimTokenLocked(uint256 tokenId);
}