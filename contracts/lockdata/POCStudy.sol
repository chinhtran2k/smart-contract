// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../interface/IMerkleTreeBase.sol";
import "./Patient.sol";
import "./Pharmacy.sol";

contract POCStudy is ERC721Base, IMerkleTreeBase {
    Patient public _patient;
    Pharmacy public _pharmacy;

    event LockedPOCPatient(uint256 pocTokenId, bytes32 rootHashPOCPatient);
    event LockedPOCPharmacy(uint256 pocTokenId, bytes32 rootHashPOCPharmacy);

    // Assign mapping
    uint256 public _rootPOCStudyPatient;
    uint256 public _rootPOCStudyPharmacy;

    mapping(uint256 => bytes32) private _rootHashPOCPatient;
    mapping(uint256 => bytes32) private _rootHashPOCPharmacy;

    // Merkle Tree structure
    mapping(uint256 => bytes32) private _rootNodeIdOfPOCPatient;
    mapping(uint256 => bytes32) private _rootNodeIdOfPOCPharmacy;

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

    function lockLevelByMerkleTree(uint level) private onlyOwner returns (bytes32 rootPatientNodeId, bytes32 rootPatientHash) {
        bytes32[] memory listLevelRootHash;
        if (level == 1) {
            listLevelRootHash = _patient.getListRootHashValue();
        } else if (level == 2) {
            listLevelRootHash = _pharmacy.getListRootHashValue();
        } else {
            revert("Level not match.");
        }
        
        uint256 listLevelRootHashLength = listLevelRootHash.length;

        uint256[] memory listTokenLevel = new uint256[](listLevelRootHashLength);
        for (uint i=1; i<listLevelRootHashLength+1; i++) {
            listTokenLevel[i] = i;
        }

        require(listLevelRootHashLength > 0, "This level do not have root hash value.");

        // Add 0x00 to bottom level if list has odd number of root hash value
        if ((listLevelRootHashLength % 2) == 1) {
            listLevelRootHashLength = listLevelRootHashLength + 1;
            uint256[] memory templistTokenLevelRootHash = new uint256[](listLevelRootHashLength);
            templistTokenLevelRootHash = copyArrayToArrayUINT256(listTokenLevel, templistTokenLevelRootHash);
            listTokenLevel = templistTokenLevelRootHash;
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
            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                    listLevelRootHash[i],
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

    constructor(address patientAddress, address pharmacyAddress, address authAddress)
        ERC721Base("Proof of Concept Study", "POCStudy", authAddress)
    {
        _patient = Patient(patientAddress);
        _pharmacy = Pharmacy(pharmacyAddress);
    }

    function mint(string memory uri, uint256 level) public onlyOwner {
        uint256 tokenId = super.mint(uri);

        // Lock level
        if (level == 1) {
            (_rootNodeIdOfPOCPatient[tokenId], _rootHashPOCPatient[tokenId]) = lockLevelByMerkleTree(level);
            _rootPOCStudyPatient = tokenId;
            emit LockedPOCPatient(tokenId, _rootHashPOCPatient[tokenId]);
        } else if (level == 2) {
            (_rootNodeIdOfPOCPharmacy[tokenId], _rootHashPOCPharmacy[tokenId]) = lockLevelByMerkleTree(level);
            _rootPOCStudyPharmacy = tokenId;
            emit LockedPOCPharmacy(tokenId, _rootHashPOCPharmacy[tokenId]);
        } else {
            revert("Level not match.");
        }
    }

    function getRootHashPOCPatient() public view returns (bytes32) {
        return _rootHashPOCPatient[_rootPOCStudyPatient];
    }
    function getRootHashPOCPharmacy() public view returns (bytes32) {
        return _rootHashPOCPharmacy[_rootPOCStudyPharmacy];
    }

    function getRootNodeIdPOCPatient() public view returns (bytes32) {
        return _rootNodeIdOfPOCPatient[_rootPOCStudyPatient];
    }
    function getRootNodeIdPOCPharmacy() public view returns (bytes32) {
        return _rootNodeIdOfPOCPharmacy[_rootPOCStudyPharmacy];
    }

    function getRootTokenIdPOCPatient() public view returns (uint256) {
        return _rootPOCStudyPatient;
    }
    function getRootTokenIdPOCPharmacy() public view returns (uint256) {
        return _rootPOCStudyPharmacy;
    }
}