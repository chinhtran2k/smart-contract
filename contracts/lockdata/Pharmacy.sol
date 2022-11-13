// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IPatient.sol";
import "../interface/IMerkleTreeBase.sol";

contract Pharmacy is ERC721Base, IPatient, IMerkleTreeBase {
    // Assign mapping
    mapping(uint256 => address) private _pharmacyOfTokenIds;
    mapping(address => uint256) private _tokenIdOfPharmacy;
    mapping(address => bytes32) private _rootHashValuesOfPharmacy;
    bytes32[] public _listRootHashValue;

    // Mapping Pharmacy to root MerkleNode
    mapping(address => bytes32) private _rootNodeIdsOfPharmacy;

    DDR public _DDR;

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

    function lockDIDByMerkleTree(address pharmacyDID) private onlyOwner returns (bytes32 rootPharmacyNodeId, bytes32 rootPharmacyHash){
        uint256[] memory listDDROfPharmacy = _DDR.getListDDRHashValueOfPharmacy(pharmacyDID);
        uint256 listDDRLength = listDDROfPharmacy.length;

        require(listDDRLength > 0, "Pharmacy do not have DDR.");

        // Add 0x00 to bottom level if Pharmacy has odd number of DDR
        if ((listDDRLength % 2) == 1) {
            listDDRLength = listDDRLength + 1;
            uint256[] memory templistDDROfPharmacy = new uint256[](listDDRLength);
            templistDDROfPharmacy = copyArrayToArrayUINT256(listDDROfPharmacy, templistDDROfPharmacy);
            listDDROfPharmacy = templistDDROfPharmacy;
        }

        // Clear temporary memory
        while (queueNode.length != 0) {
            queueNode.pop();
        }
        while (tempNode.length != 0) {
            tempNode.pop();
        }

        // Initial bottom level data
        for (uint i = 0; i < listDDRLength; i++) {
            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                    _DDR.getDDRHash(listDDROfPharmacy[i]),
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

        bytes32 _rootPharmacyNodeId = queueNode[0];
        bytes32 _rootPharmacyHash = _allNodes[queueNode[0]].hashValue;

        return(_rootPharmacyNodeId, _rootPharmacyHash);
    }
    
    function getNodeData(bytes32 nodeId) public override view returns (MerkleNode memory) {
        return _allNodes[nodeId];
    }

    function getCurrentQueue() public override view returns (bytes32[] memory) {
        return queueNode;
    }
    // ***

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("Pharmacy", "PM", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
    }

    function mint(address pharmacyDID, string memory uri) public onlyOwner returns(uint256){
        uint256 tokenId = super.mint(uri);

        (bytes32 _rootPharmacyNodeId, bytes32 _rootPharmacyHash) = lockDIDByMerkleTree(pharmacyDID);
        _pharmacyOfTokenIds[tokenId] = pharmacyDID;
        _tokenIdOfPharmacy[pharmacyDID] = tokenId;
        _rootNodeIdsOfPharmacy[pharmacyDID] = _rootPharmacyNodeId;
        _rootHashValuesOfPharmacy[pharmacyDID] = _rootPharmacyHash;

        _listRootHashValue.push(_rootPharmacyHash);
        emit PharmacyLockTokenMinted(tokenId, pharmacyDID, _rootPharmacyNodeId, _rootPharmacyHash);
        return tokenId;
    }

    function getPharmacyAddressOf(uint256 tokenId) public view returns (address) {
        return _pharmacyOfTokenIds[tokenId];
    }

    function getTokenIdOfPharmacy(address pharmacyDID) public view returns (uint256) {
        return _tokenIdOfPharmacy[pharmacyDID];
    }

    function getPharmacyRootHashValue(address PharmacyDID) public view returns (bytes32) {
        return _rootHashValuesOfPharmacy[PharmacyDID];
    }

    function getPharmacyRootNodeId(address PharmacyDID) public view returns (bytes32){
        return _rootNodeIdsOfPharmacy[PharmacyDID];
    }
}
