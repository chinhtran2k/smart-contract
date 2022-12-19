// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IPatient.sol";
import "../interface/IMerkleTreeBase.sol";

contract Patient is ERC721Base, IPatient, IMerkleTreeBase {
    // Assign mapping
    mapping(uint256 => address) private _patientOfTokenIds;
    mapping(address => uint256) private _tokenIdOfPatients;
    mapping(address => bytes32) private _rootHashValuesOfPatient;
    mapping(uint256 => bytes32) private _rootHashValuesOfTokenId;
    mapping(address => bool) private _isPatientMinted;
    bytes32[] private _listRootHashValue;
    address[] private _listAddressPatient;

    // Mapping patient to root MerkleNode
    mapping(address => bytes32) private _rootNodeIdsOfPatient;
    address public claimIssuer;
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

    function lockDIDByMerkleTree(address patientDID) private onlyOwner returns (bytes32 rootPatientNodeId, bytes32 rootPatientHash){
        uint256[] memory listDDROfPatient = _DDR.getListDDRTokenIdOfPatient(patientDID);
        uint256 listDDRLength = listDDROfPatient.length;

        require(listDDRLength > 0, "Patient do not have DDR.");

        // Add 0x00 to bottom level if patient has odd number of DDR
        if ((listDDRLength % 2) == 1) {
            listDDRLength = listDDRLength + 1;
            uint256[] memory templistDDROfPatient = new uint256[](listDDRLength);
            templistDDROfPatient = copyArrayToArrayUINT256(listDDROfPatient, templistDDROfPatient);
            listDDROfPatient = templistDDROfPatient;
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
            // Combine DDR and consented address
            bytes32 combineConsentedDID = 0x0000000000000000000000000000000000000000000000000000000000000000;

            if (_DDR.getDIDConsentedOf(listDDROfPatient[i]).length > 0) {
                address[] memory consentedDID = _DDR.getDIDConsentedOf(listDDROfPatient[i]);
                combineConsentedDID = keccak256(abi.encodePacked(consentedDID));
            }
            

            bytes32 ddrCombinedHash = keccak256(abi.encodePacked(
                _DDR.getDDRHash(listDDROfPatient[i]),
                combineConsentedDID));

            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                    ddrCombinedHash,
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

        bytes32 _rootPatientNodeId = queueNode[0];
        bytes32 _rootPatientHash = _allNodes[queueNode[0]].hashValue;
        
        return(_rootPatientNodeId, _rootPatientHash);
    }
    
    function getNodeData(bytes32 nodeId) public override view returns (MerkleNode memory) {
        return _allNodes[nodeId];
    }

    function getCurrentQueue() public override view returns (bytes32[] memory) {
        return queueNode;
    }
    // ***

    // PatientLock part
    constructor(address _ddrAddress, address _claimHolder, address _authAddress)
        ERC721Base("Patient Lock", "PT", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
        claimIssuer = _claimHolder;
    }

    function getHashClaim(address patientDID) public view returns(bytes32){
        ClaimHolder claimHolder = ClaimHolder(patientDID);
        uint256 scheme;
        address issuer;
        bytes memory signature;
        bytes memory data;
        string memory uri;
        string[] memory claimKey = claimHolder.getClaimsKeyOwned();
        bytes32[] memory listHashDataPatient = new bytes32[](claimKey.length);
        for(uint256 i=0; i< claimKey.length; i++){
            bytes32 _claimId = keccak256(abi.encodePacked(claimIssuer, claimKey[i]));
            (claimKey[i], scheme, issuer, signature, data, uri) = claimHolder.getClaim(_claimId);
            listHashDataPatient[i] = keccak256(abi.encodePacked(claimKey[i], scheme, issuer, signature, data, uri));
        }
        bytes32 hashDataPatient = keccak256(abi.encodePacked(listHashDataPatient));
        return hashDataPatient;
    }

    function setLockInfo(uint256 tokenId, address patientDID, bytes32 rootPatientHash, bytes32 claimData) internal {
        bytes32 newHashValue = keccak256(abi.encodePacked(patientDID, rootPatientHash, claimData));
        _patientOfTokenIds[tokenId] = patientDID;
        _tokenIdOfPatients[patientDID] = tokenId;
        _rootHashValuesOfPatient[patientDID] = newHashValue; 
        if(_isPatientMinted[patientDID] == false){
            _listAddressPatient.push(patientDID);
            _isPatientMinted[patientDID]==true;
        }
        _listRootHashValue.push(newHashValue);
        emit PatientLockTokenMinted(tokenId, patientDID, rootPatientHash, newHashValue);
    }

    //// This function only call when "Project manager" want to end the project and lock "ALL" data
    //// Because of that, mint = lock now, this function limited to onlyOwner (Project manager)
    function mint(address patientDID, string memory uri) public onlyOwner returns(uint256){
        uint256 tokenId = super.mint(uri);
    
        (bytes32 _rootPatientNodeId, bytes32 _rootPatientHash) = lockDIDByMerkleTree(patientDID);
        bytes32 claimData = getHashClaim(patientDID);
        _rootNodeIdsOfPatient[patientDID] = _rootPatientNodeId;
        setLockInfo(tokenId, patientDID, _rootPatientHash, claimData);
        return tokenId;
    }

    function getPatientAddressOf(uint256 tokenId) public view returns (address) {
        return _patientOfTokenIds[tokenId];
    }

    function getTokenIdOfPatient(address patientDID) public view returns (uint256) {
        return _tokenIdOfPatients[patientDID];
    }

    function getPatientRootHashValue(address patientDID) public view returns (bytes32) {
        return _rootHashValuesOfPatient[patientDID];
    }

    function getPatientRootNodeId(address patientDID) public view returns (bytes32){
        return _rootNodeIdsOfPatient[patientDID];
    }

    function getListRootHashValue() public view returns (bytes32[] memory) {
        return _listRootHashValue;
    }

    function getListAddressPatient() public view returns(address[] memory){
        return _listAddressPatient;
    }
}

