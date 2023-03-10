// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDRBranch.sol";
import "./DisclosureBranch.sol";
import "../interface/IPatient.sol";
import "./ClaimBranch.sol";
import "../interface/IMerkleTreeBase.sol";

contract Patient is ERC721Base, IPatient, IMerkleTreeBase {
    // Assign mapping
    mapping(uint256 => address) private _patientOfTokenIds;
    mapping(address => uint256) private _tokenIdOfPatients;
    mapping(address => bytes32) private _rootHashValuesOfPatient;
    mapping(uint256 => mapping(address => bytes32)) private _rootHashValuesOfTokenId;
    mapping(address => bool) private _isPatientMinted;
    bytes32[] private _listRootHashValue;
    address[] private _listAddressPatient;

    // Mapping patient to root MerkleNode
    mapping(address => bytes32) private _rootNodeIdsOfPatient;
    address public claimAddress;
    DDRBranch public _ddrBranch;
    ClaimBranch public _claimBranch;
    DisclosureBranch public _disclosureBranch;

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
        uint256[] memory listDDRBranch = _ddrBranch.getListTokenId(patientDID);
        uint256[] memory listDisclosureBranch = _disclosureBranch
            .getListTokenId(patientDID);

        bytes32[] memory listRootHash = new bytes32[](
            listDDRBranch.length + listDisclosureBranch.length
        );
        for (uint256 i = 0; i < listDDRBranch.length; i++) {
            listRootHash[i] = _ddrBranch.getHashDDRBranchOfTokenId(
                listDDRBranch[i],
                patientDID
            );
        }
        for (uint256 i = 0; i < listDisclosureBranch.length; i++) {
            listRootHash[i + listDDRBranch.length] = _disclosureBranch
                .getRootHashDisclosureOfTokenId(listDisclosureBranch[i], patientDID);
        }

        uint256 listLevelRootHashLength = listRootHash.length;

        // require(listLevelRootHashLength > 0, "Patient do not have DDR.");

        // Add 0x00 to bottom level if patient has odd number of DDR
        if (listLevelRootHashLength % 2 == 1) {
            listLevelRootHashLength = listLevelRootHashLength + 1;
            bytes32[] memory _tempListLevelRootHash = new bytes32[](
                listLevelRootHashLength
            );

            for (uint256 k = 0; k < listRootHash.length; k++) {
                _tempListLevelRootHash[k] = listRootHash[k];
            }
            _tempListLevelRootHash[
                listLevelRootHashLength - 1
            ] = 0x0000000000000000000000000000000000000000000000000000000000000000;
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
        for (uint256 i = 0; i < listLevelRootHashLength; i++) {
            bytes32 rootHashTemp = listRootHash[i];
            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                rootHashTemp,
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

        bytes32 _rootLevelNodeId = queueNode[0];
        bytes32 _rootLevelHash = _allNodes[queueNode[0]].hashValue;

        return (_rootLevelNodeId, _rootLevelHash);
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
    constructor(
        address _claimBranchAddress,
        address _ddrBranchAddress,
        address _disclosureBranchAddress,
        address _authAddress
    ) ERC721Base("Patient Lock", "Patient LV3", _authAddress) {
        _ddrBranch = DDRBranch(_ddrBranchAddress);
        _disclosureBranch = DisclosureBranch(_disclosureBranchAddress);
        _claimBranch = ClaimBranch(_claimBranchAddress);
    }

    function setLockInfo(
        uint256 tokenId,
        address patientDID,
        bytes32 hashClaimPatient
    ) internal {
        bytes32 newHashValue;
        bytes32 rootPatientHash;
        bytes32 rootPatientNodeId;
        if(_ddrBranch.getListTokenId(patientDID).length == 0){
            newHashValue = 0x0000000000000000000000000000000000000000000000000000000000000000;
            rootPatientNodeId = 0x0000000000000000000000000000000000000000000000000000000000000000;
            rootPatientHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        }
        else{
            ( rootPatientNodeId, rootPatientHash ) = lockDIDByMerkleTree(patientDID);
            newHashValue = keccak256(
            abi.encodePacked(
                patientDID,
                rootPatientHash,
                hashClaimPatient,
                tokenId
            )
        );
        }
        _rootNodeIdsOfPatient[patientDID] = rootPatientNodeId;
        _patientOfTokenIds[tokenId] = patientDID;
        _tokenIdOfPatients[patientDID] = tokenId;
        _rootHashValuesOfPatient[patientDID] = newHashValue;
        _rootHashValuesOfTokenId[tokenId][patientDID] = newHashValue;
        if (_isPatientMinted[patientDID] == false) {
            _listAddressPatient.push(patientDID);
            _isPatientMinted[patientDID] = true;
        }
        _listRootHashValue.push(newHashValue);
        emit PatientLockTokenMinted(
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
        require(
            _IAuth.checkAuth(
                ClaimHolder(patientDID),
                "ACCOUNT_TYPE",
                "PATIENT"
            ),
            "Patient DID is not valid!"
        );
        bytes32 hashClaimPatient = _claimBranch.getHashValueClaim(patientDID);
        setLockInfo(tokenId, patientDID, hashClaimPatient);
        return tokenId;
    }

    function getPatientAddressOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        return _patientOfTokenIds[tokenId];
    }

    function getTokenIdOfPatient(address patientDID)
        public
        view
        returns (uint256)
    {
        return _tokenIdOfPatients[patientDID];
    }

    function getPatientRootHashValue(address patientDID)
        public
        view
        returns (bytes32)
    {
        return _rootHashValuesOfPatient[patientDID];
    }

    function getRootHashValueOfTokenId(uint256 tokenId, address patientDID)
        public
        view
        returns (bytes32)
    {
        return _rootHashValuesOfTokenId[tokenId][patientDID];
    }

    function getPatientRootNodeId(address patientDID)
        public
        view
        returns (bytes32)
    {
        return _rootNodeIdsOfPatient[patientDID];
    }

    function getListRootHashValue() public view returns (bytes32[] memory) {
        return _listRootHashValue;
    }

    function getListAddressPatient() public view returns (address[] memory) {
        return _listAddressPatient;
    }
}
