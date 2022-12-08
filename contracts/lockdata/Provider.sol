// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ERC721Base.sol";
import "../DID/ClaimHolder.sol";
import "../interface/IProvider.sol";
import "../interface/IMerkleTreeBase.sol";

contract Provider is ERC721Base, IProvider, IMerkleTreeBase {
    // Assign mapping
    mapping(uint256 => address) private _providerOfTokenIds;
    mapping(address => uint256) private _tokenIdOfProvider;
    mapping(uint256 => bytes32) private _ddrHash;
    bytes32[] private _listRootHashValueOfProvider;
    uint256[] private _listTokenProvider;

    // Mapping Provider to root MerkleNode
    mapping(address => bytes32) private _rootNodeIdsOfProvider;
    mapping(address => bytes32) private _rootHashValuesOfProvider;

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

    function lockDIDByMerkleTree() private onlyOwner returns (bytes32 rootProviderNodeId, bytes32 rootProvidertHash){
        uint256 listDIDLength = _listTokenProvider.length;

        require(listDIDLength > 0, "Provider do not have DDR.");

        // Add 0x00 to bottom level if Provider has odd number of DDR
        if ((listDIDLength % 2) == 1) {
            listDIDLength = listDIDLength + 1;
            uint256[] memory temp_listTokenProvider = new uint256[](listDIDLength);
            temp_listTokenProvider = copyArrayToArrayUINT256(_listTokenProvider, temp_listTokenProvider);
            _listTokenProvider = temp_listTokenProvider;
        }

        // Clear temporary memory
        while (queueNode.length != 0) {
            queueNode.pop();
        }
        while (tempNode.length != 0) {
            tempNode.pop();
        }

        // Initial bottom level data
        for (uint i = 0; i < listDIDLength; i++) {
            // Bottom level doesn't have child
            MerkleNode memory merkleNodeTemp = MerkleNode(
                    _ddrHash[_listTokenProvider[i]],
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

        bytes32 _rootProviderNodeId = queueNode[0];
        bytes32 _rootProviderHash = _allNodes[queueNode[0]].hashValue;
        
        return(_rootProviderNodeId, _rootProviderHash);
    }
    
    function getNodeData(bytes32 nodeId) public override view returns (MerkleNode memory) {
        return _allNodes[nodeId];
    }

    function getCurrentQueue() public override view returns (bytes32[] memory) {
        return queueNode;
    }
    // ***

    // ProviderLock part
    constructor(address _authAddress)
        ERC721Base("Provider", "HP", _authAddress)
    {
    }

    //// This function only call when "Project manager" want to end the project and lock "ALL" data
    //// Because of that, mint = lock now, this function limited to onlyOwner (Project manager)
    function mint(address ProviderDID, string memory claimKey, string memory uri) public onlyOwner returns(uint256){
        uint256 tokenId = super.mint(uri);
        _listTokenProvider.push(tokenId);
        bytes32 _claimId = keccak256(abi.encodePacked(ProviderDID, claimKey));
        ClaimHolder claimHolder = ClaimHolder(ProviderDID);
        uint256 scheme;
        address issuer;
        bytes memory signature;
        bytes memory data;
        (claimKey, scheme, issuer, signature, data, uri) = claimHolder.getClaim(_claimId);
        bytes32 HashDataDID =  keccak256(abi.encodePacked(claimKey, scheme, issuer, signature, data));

        bytes32 newHashValue = keccak256(abi.encodePacked(ProviderDID, HashDataDID));
        _ddrHash[tokenId] = newHashValue;
        
        (bytes32 _rootProviderNodeId, bytes32 _rootProviderHash) = lockDIDByMerkleTree();

        lockTokenMinted(ProviderDID, tokenId, _rootProviderNodeId, _rootProviderHash);

        return tokenId;
    }

    function lockTokenMinted(address ProviderDID, uint256 tokenId, bytes32 _rootProviderNodeId, bytes32 _rootProviderHash) internal {
        setProviderAddressOf(tokenId, ProviderDID);
        setTokenIdOfProvider(ProviderDID, tokenId);
        setProviderRootNodeId(ProviderDID, _rootProviderNodeId);
        setProviderRootHashValue(ProviderDID, _rootProviderHash);
        pushToListRootHashValue(_rootProviderHash);
        emit ProviderLockTokenMinted(tokenId, ProviderDID, _rootProviderNodeId, _rootProviderHash);
    }

    function getProviderAddressOf(uint256 tokenId) public view returns (address) {
        return _providerOfTokenIds[tokenId];
    }

    function setProviderAddressOf(uint256 tokenId, address ProviderDID) internal {
        _providerOfTokenIds[tokenId] = ProviderDID;
    }

    function getTokenIdOfProvider(address ProviderDID) public view returns (uint256) {
        return _tokenIdOfProvider[ProviderDID];
    }

    function setTokenIdOfProvider(address ProviderDID, uint256 tokenId) internal {
        _tokenIdOfProvider[ProviderDID] = tokenId;
    }

    function getProviderRootHashValue(address ProviderDID) public view returns (bytes32) {
        return _rootHashValuesOfProvider[ProviderDID];
    }

    function setProviderRootHashValue(address ProviderDID, bytes32 _rootHashValue) internal {
        _rootHashValuesOfProvider[ProviderDID] = _rootHashValue;
    }

    function getProviderRootNodeId(address ProviderDID) public view returns (bytes32){
        return _rootNodeIdsOfProvider[ProviderDID];
    }

    function setProviderRootNodeId(address ProviderDID, bytes32 _rootProviderNodeId) internal {
        _rootNodeIdsOfProvider[ProviderDID] = _rootProviderNodeId;
    }

    function getListRootHashValue() public view returns (bytes32[] memory) {
        return _listRootHashValueOfProvider;
    }

    function pushToListRootHashValue(bytes32 _rootProviderHash) internal {
        _listRootHashValueOfProvider.push(_rootProviderHash);
    }
}

