// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../interface/IMerkleTreeBase.sol";
import "./Patient.sol";

contract POCStudy is ERC721Base, IMerkleTreeBase {
    Patient public _patient;

    event LockedPOC(uint256 pocTokenId, bytes32 rootHashPOC, string message);

    // Assign mapping
    uint256 public _rootPOCStudy;

    mapping(uint256 => bytes32) private _rootHashPOC;

    // Merkle Tree structure
    mapping(uint256 => bytes32) private _rootNodeIdOfPOC;

    bytes32[] public _listRootHashValue;

    // Merkle Tree structure
    mapping(bytes32 => MerkleNode) private _allNodes;
    uint256 public merkleLength = 0;

    // Temporary memory for caculating
    bytes32[] private queueNode;
    bytes32[] private tempNode;

    // Implementation for MerkleTree part
    // ***
    function copyArrayToArrayUINT256(uint256[] memory arrFrom, uint256[] memory arrTo) public override pure returns(uint256[] memory) {
        require(arrTo.length >= arrFrom.length, "Destination array not match size.");
        for (uint i = 0; i < arrFrom.length; i++) {
            arrTo[i] = arrFrom[i];
        }
        return arrTo;
    }

    function popQueue(uint index) private onlyOwner {
        // uint256 valueAtIndex = nodeArr[index]
        for (uint i = index; i < queueNode.length-1; i++) {
            queueNode[i] = queueNode[i+1];
        }
        queueNode.pop();
    }

    function lockStudyByMerkleTree() private onlyOwner returns 
        (bytes32 rootNodeId, bytes32 rootHash) 
        // (uint256[] memory)
    {
        address[] memory listPatientAddress = _patient.getListAddressPatient();
        
        bytes32[] memory listRootHash = new bytes32[](listPatientAddress.length);
        for (uint i=0; i<listPatientAddress.length; i++) {
            listRootHash[i] = _patient.getPatientRootHashValue(listPatientAddress[i]);
        }

        uint256 listLevelRootHashLength = listRootHash.length;

        require(listLevelRootHashLength > 0, "pcostudy level has no root hash value.");
        
        // Add 0x00 to bottom level if list has odd number of root hash value
        if (listLevelRootHashLength % 2 == 1) {
            listLevelRootHashLength = listLevelRootHashLength + 1;
            bytes32[] memory _tempListLevelRootHash = new bytes32[](listLevelRootHashLength);

            for (uint256 k = 0; k < listRootHash.length; k++) {
                _tempListLevelRootHash[k] = listRootHash[k];
            }
            _tempListLevelRootHash[listLevelRootHashLength-1] = 0x0000000000000000000000000000000000000000000000000000000000000000;
            listRootHash = _tempListLevelRootHash;
        }

        // Clear temporary memory
        while (queueNode.length != 0) {
            queueNode.pop();
        }
        while (tempNode.length != 0) {
            tempNode.pop();
        }

        // Initial bottom level data 
        for (uint i = 0; i < listLevelRootHashLength; i++) {
            bytes32 rootHashTemp = listRootHash[i];
            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                    rootHashTemp,
                    0x0000000000000000000000000000000000000000000000000000000000000000,
                    0x0000000000000000000000000000000000000000000000000000000000000000
                );

            // Generate unique node id base on hashValue
            bytes32 nodeId = keccak256(abi.encodePacked(
                merkleNodeTemp.hashValue, merkleNodeTemp.nodeLeft, merkleNodeTemp.nodeRight
            ));
            queueNode.push(nodeId);
            _allNodes[nodeId] = merkleNodeTemp;
            merkleLength += 1;
        }

        // Build merkle tree
        while (queueNode.length > 1) {
            // Clear memory
            while (tempNode.length != 0) {
                tempNode.pop();
            }

            // Handle even queueNode
            if ((queueNode.length % 2) == 1) {
                queueNode.push(0x0000000000000000000000000000000000000000000000000000000000000000);
            }

            // Get queue length
            uint nodeLen = queueNode.length;
            for (uint j = 0; j < nodeLen; j+=2) {
                bytes32 nodeLeft = queueNode[0];
                bytes32 nodeRight = queueNode[1];
                bytes32 nodeHashValue = keccak256(abi.encodePacked(_allNodes[queueNode[0]].hashValue, _allNodes[queueNode[1]].hashValue));
                bytes32 nodeId = keccak256(abi.encodePacked(
                    nodeHashValue,
                    nodeLeft,
                    nodeRight
                ));
                MerkleNode memory nodeTemp = MerkleNode(nodeHashValue, nodeLeft, nodeRight);

                _allNodes[nodeId] = nodeTemp;

                // Push to temp
                tempNode.push(nodeId);

                // Remove in node queue
                popQueue(0);
                popQueue(0);
            }
            queueNode = tempNode;
        }

        bytes32 _rootLevelNodeId = queueNode[0];
        bytes32 _rootLevelHash = _allNodes[queueNode[0]].hashValue;

        return(_rootLevelNodeId, _rootLevelHash);
    }   

    function getNodeData(bytes32 nodeId) public override view returns (MerkleNode memory) {
        return _allNodes[nodeId];
    }

    function getCurrentQueue() public override view returns (bytes32[] memory) {
        return queueNode;
    }

    constructor(address patientAddress, address authAddress)
        ERC721Base("POC Study Lock", "POCStudy", authAddress)
    {
        _patient = Patient(patientAddress);
    }

    function mint(string memory uri, string memory message) public onlyOwner returns (uint256) {
        uint256 tokenId = super.mint(uri);

        // Lock level
        (_rootNodeIdOfPOC[tokenId], _rootHashPOC[tokenId]) = lockStudyByMerkleTree();
        _rootPOCStudy = tokenId;
        emit LockedPOC(tokenId, _rootHashPOC[tokenId], message);

        return tokenId;
    }

    function getRootHashPOC() public view returns (bytes32) {
        return _rootHashPOC[_rootPOCStudy];
    }
    function getRootNodeIdPOC() public view returns (bytes32) {
        return _rootNodeIdOfPOC[_rootPOCStudy];
    }

    function getRootTokenIdPOC() public view returns (uint256) {
        return _rootPOCStudy;
    }
}