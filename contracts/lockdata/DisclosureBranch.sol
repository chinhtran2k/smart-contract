// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "./DDR.sol";
import "../interface/IDisclosureBranch.sol";
import "../interface/IMerkleTreeBase.sol";

contract DisclosureBranch is ERC721Base, IDisclosureBranch, IMerkleTreeBase {
    // Assign mapping
    mapping(uint256 => address) private _providerOfTokenIds;
    mapping(address => bytes32[]) private _listHashDisclosureOfProvider;
    mapping(uint256 => bytes32) private rootHashDisclosureOfTokenId;
    bytes32[] private _listRootHashClosure;

    // Mapping provider to root MerkleNode
    mapping(address => bytes32) private _rootNodeIdsPatientOfProvider;
    mapping(address => uint256[]) private _listTokenId;

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

    function lockDIDByMerkleTree(address patientDID, address providerDID)
        private
        onlyOwner
        returns (bytes32 rootProviderNodeId, bytes32 rootProviderHash)
    {
        uint256[] memory listTokenIdDisclosure = _DDR
            .getListDDRTokenIdOfProvider(providerDID, patientDID);
        uint256 listDDRLength = listTokenIdDisclosure.length;

        require(listDDRLength > 0, "provider do not have DDR.");

        // Add 0x00 to bottom level if patient has odd number of DDR
        if ((listDDRLength % 2) == 1) {
            listDDRLength = listDDRLength + 1;
            uint256[] memory templistDisclosure = new uint256[](listDDRLength);
            templistDisclosure = copyArrayToArrayUINT256(
                listTokenIdDisclosure,
                templistDisclosure
            );
            listTokenIdDisclosure = templistDisclosure;
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
                _DDR.getDDRHash(listTokenIdDisclosure[i]),
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

        bytes32 _rootDisclosureNodeId = queueNode[0];
        bytes32 _rootDisclosureHash = _allNodes[queueNode[0]].hashValue;

        return (_rootDisclosureNodeId, _rootDisclosureHash);
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

    constructor(address _ddrAddress, address _authAddress)
        ERC721Base("provider", "PM", _authAddress)
    {
        _DDR = DDR(_ddrAddress);
    }

    function setLockInfo(
        uint256 tokenId,
        address patientDID,
        address providerDID,
        bytes32 rootDisclosuretHash
    ) internal {
        bytes32 newHashValue = keccak256(
            abi.encodePacked(providerDID, rootDisclosuretHash, tokenId)
        );
        _providerOfTokenIds[tokenId] = providerDID;
        _listHashDisclosureOfProvider[providerDID].push(newHashValue);
        rootHashDisclosureOfTokenId[tokenId] = newHashValue;
        _listTokenId[patientDID].push(tokenId);
        _listRootHashClosure.push(newHashValue);
        emit disclosureLockTokenMinted(
            tokenId,
            providerDID,
            rootDisclosuretHash,
            newHashValue
        );
    }

    function mint(
        address patientDID,
        address providerDID,
        string memory uri
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = super.mint(uri);

        ( bytes32 _rootDisclosureNodeId, bytes32 _rootDisclosureHash) = lockDIDByMerkleTree(providerDID, patientDID);
        _rootNodeIdsPatientOfProvider[patientDID] = _rootDisclosureNodeId;
        setLockInfo(tokenId, patientDID, providerDID, _rootDisclosureHash);
        return tokenId;
    }

    function getProviderAddressOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        return _providerOfTokenIds[tokenId];
    }

    function getListHashDisclosureOfProvider(address providerDID)
        public
        view
        returns (bytes32[] memory)
    {
        return _listHashDisclosureOfProvider[providerDID];
    }

    function getTokenIdRootHashDisclosure(uint256 tokenId)
        public
        view
        returns (bytes32)
    {
        return rootHashDisclosureOfTokenId[tokenId];
    }

    function getProviderRootNodeId(address providerDID)
        public
        view
        returns (bytes32)
    {
        return _rootNodeIdsPatientOfProvider[providerDID];
    }

    function getListTokenId(address patientDID)
        public
        view
        returns (uint256[] memory)
    {
        return _listTokenId[patientDID];
    }

    function getListRootHashDisclosure()
        public
        view
        returns (bytes32[] memory)
    {
        return _listRootHashClosure;
    }
}
