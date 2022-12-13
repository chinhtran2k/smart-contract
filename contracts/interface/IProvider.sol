// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProvider {
    event ProviderLockTokenMinted(uint256 providerTokenId, address providerDID, bytes32 rootHash);
    event ProviderTokenLocked(uint256 tokenId);
}