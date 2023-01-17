// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDDRBranch.sol";
import "../interface/IMerkleTreeBase.sol";

contract DDRBranch is ERC721Base, IDDRBranch, IMerkleTreeBase {
    // Assign mapping
    mapping(uint256 => address) private _patientOfTokenIds;
    mapping(address => bytes32) private _hashDDROfPatients;
    mapping(uint256 => mapping(address => bytes32)) private _rootHashDDROfTokenId;
    bytes32[] private _listRootHashDDR;
    mapping(address => uint256[]) private _listTokenId;

    // Mapping patient to root MerkleNode
    mapping(address => bytes32) private _rootNodeIdsOfPatient;
    DDR public _DDR;

    // Merkle Tree structure
    mapping(bytes32 => MerkleNode) private _allNodes;
    uint256 public merkleLength = 0;

    // Temporary memory for caculating
    bytes32[] private queueNode;
    bytes32[] private tempNode;

    // Implementation for MerkleTree part
    // ***
    function copyArrayToArrayUINT256(
        uint256[] memory arrFrom,
        uint256[] memory arrTo
    ) public pure override returns (uint256[] memory) {
        require(
            arrTo.length >= arrFrom.length,
            "Destination array not match size."
        );
        for (uint256 i = 0; i < arrFrom.length; i++) {
            arrTo[i] = arrFrom[i];
        }
        return arrTo;
    }

    function popQueue(uint256 index) private onlyOwner {
        // uint256 valueAtIndex = nodeArr[index]
        for (uint256 i = index; i < queueNode.length - 1; i++) {
            queueNode[i] = queueNode[i + 1];
        }
        queueNode.pop();
    }

    function lockDIDByMerkleTree(address patientDID)
        private
        onlyOwner
        returns (bytes32 rootPatientNodeId, bytes32 rootPatientHash)
    {
        uint256[] memory listTokenDDROfPatient = _DDR
            .getListDDRTokenIdOfPatient(patientDID);
        uint256 listDDRLength = listTokenDDROfPatient.length;

        // require(listDDRLength > 0, "Patient do not have DDR.");
        if (listDDRLength == 0) {
            return (
                0x0000000000000000000000000000000000000000000000000000000000000000, 
                0x0000000000000000000000000000000000000000000000000000000000000000
            );
        }

        // Add 0x00 to bottom level if patient has odd number of DDR
        if ((listDDRLength % 2) == 1) {
            listDDRLength = listDDRLength + 1;
            uint256[] memory templistDDROfPatient = new uint256[](
                listDDRLength
            );
            templistDDROfPatient = copyArrayToArrayUINT256(
                listTokenDDROfPatient,
                templistDDROfPatient
            );
            listTokenDDROfPatient = templistDDROfPatient;
        }

        // Clear temporary memory
        while (queueNode.length != 0) {
            queueNode.pop();
        }
        while (tempNode.length != 0) {
            tempNode.pop();
        }

        // Initial bottom level data
        for (uint256 i = 0; i < listDDRLength; i++) {
            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                _DDR.getDDRHash(listTokenDDROfPatient[i], patientDID),
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000000000000000000000000000
            );

            // Generate unique node id base on hashValue
            bytes32 nodeId = keccak256(
                abi.encodePacked(
                    merkleNodeTemp.hashValue,
                    merkleNodeTemp.nodeLeft,
                    merkleNodeTemp.nodeRight
                )
            );
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
                queueNode.push(
                    0x0000000000000000000000000000000000000000000000000000000000000000
                );
            }

            // Get queue length
            uint256 nodeLen = queueNode.length;
            for (uint256 j = 0; j < nodeLen; j += 2) {
                bytes32 nodeLeft = queueNode[0];
                bytes32 nodeRight = queueNode[1];
                bytes32 nodeHashValue = keccak256(
                    abi.encodePacked(
                        _allNodes[queueNode[0]].hashValue,
                        _allNodes[queueNode[1]].hashValue
                    )
                );
                bytes32 nodeId = keccak256(
                    abi.encodePacked(nodeHashValue, nodeLeft, nodeRight)
                );
                MerkleNode memory nodeTemp = MerkleNode(
                    nodeHashValue,
                    nodeLeft,
                    nodeRight
                );

                _allNodes[nodeId] = nodeTemp;

                // Push to temp
                tempNode.push(nodeId);

                // Remove in node queue
                popQueue(0);
                popQueue(0);
            }
            queueNode = tempNode;
        }

        bytes32 _rootPatientNodeId = queueNode[0];
        bytes32 _rootPatientHash = _allNodes[queueNode[0]].hashValue;

        return (_rootPatientNodeId, _rootPatientHash);
    }

    function getNodeData(bytes32 nodeId)
        public
        view
        override
        returns (MerkleNode memory)
    {
        return _allNodes[nodeId];
    }

    function getCurrentQueue() public view override returns (bytes32[] memory) {
        return queueNode;
    }

    // ***

    // PatientLock part
    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("DDRBranch Lock", "DDR LV2", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
    }

    function setLockInfo(
        uint256 tokenId,
        address patientDID,
        bytes32 rootPatientHash
    ) internal {
        bytes32 newHashValue = keccak256(
            abi.encodePacked(patientDID, rootPatientHash, tokenId)
        );
        _patientOfTokenIds[tokenId] = patientDID;
        _hashDDROfPatients[patientDID] = newHashValue;
        _rootHashDDROfTokenId[tokenId][patientDID] = newHashValue;
        _listTokenId[patientDID].push(tokenId);
        _listRootHashDDR.push(newHashValue);
        emit DDRBranchLockTokenMinted(
            tokenId,
            patientDID,
            rootPatientHash,
            newHashValue
        );
    }

    //// This function only call when "Project manager" want to end the project and lock "ALL" data
    //// Because of that, mint = lock now, this function limited to onlyOwner (Project manager)
    function mint(address patientDID, string memory uri)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = super.mint(uri);

        ( bytes32 _rootPatientNodeId, bytes32 _rootPatientHash ) = lockDIDByMerkleTree(patientDID);
        _rootNodeIdsOfPatient[patientDID] = _rootPatientNodeId;
        setLockInfo(tokenId, patientDID, _rootPatientHash);
        return tokenId;
    }

    function getPatientAddressOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        return _patientOfTokenIds[tokenId];
    }

    function getHashDDROfPatient(address patientDID)
        public
        view
        returns (bytes32)
    {
        return _hashDDROfPatients[patientDID];
    }

    function getHashDDRBranchOfTokenId(uint256 tokenId, address patientDID)
        public
        view
        returns (bytes32)
    {
        return _rootHashDDROfTokenId[tokenId][patientDID];
    }

    function getPatientRootNodeId(address patientDID)
        public
        view
        returns (bytes32)
    {
        return _rootNodeIdsOfPatient[patientDID];
    }

    function getListRootHashDDR() public view returns (bytes32[] memory) {
        return _listRootHashDDR;
    }

    function getListTokenId(address patientDID)
        public
        view
        returns (uint256[] memory)
    {
        return _listTokenId[patientDID];
    }
}
