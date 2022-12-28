// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDisclosureBranch {
    event disclosureLockTokenMinted(uint256 tokenId, address providerDID, bytes32 rootHash, bytes32 newHashValue);
}