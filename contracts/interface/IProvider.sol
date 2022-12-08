// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProvider {
    event ProviderLockTokenMinted(uint256 hospitalTokenId, address hospitalDID, bytes32 rootNodeId, bytes32 rootHash);
}