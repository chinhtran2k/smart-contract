// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMerkleTreeBase {
    struct MerkleNode {
        bytes32 hashValue;
        bytes32 nodeLeft;
        bytes32 nodeRight;
    }

    // "popQueue" function is private but Solidity can not override external, please implement it yourself
    // function popQueue(uint index) external;

    // "lockDIDByMerkleTree" function is private but Solidity can not override external, please implement it yourself
    // function lockDIDByMerkleTree(address identity) external returns (bytes32 rootNodeId, bytes32 rootHash);
    
    function getNodeData(bytes32 nodeId) external view returns (MerkleNode memory);

    function getCurrentQueue() external view returns (bytes32[] memory);

    // Helper
    function copyArrayToArrayUINT256(uint256[] memory arrFrom, uint256[] memory arrTo) external pure returns(uint256[] memory);
}