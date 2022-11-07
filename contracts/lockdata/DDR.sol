// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../interface/IDDR.sol";

 contract DDR is ERC721Base, IDDR {
  mapping(uint256 => uint256[]) private _ddrHistory;
  mapping(uint256 => bytes32) public _ddrHash;
  mapping(uint256 => bool) private _isDDRLocked;
  mapping(uint256 => mapping(address => bool))  private _isDisclosable;
  mapping(address => bytes32) private _DDRPatient;
  bytes32 private _hashValue;
  mapping(uint256 => address) private _owner;

    modifier _valiDDRList(
        uint256 ddrId,
        address senderAddress
    ) {
            require(
                !_isDDRLocked[ddrId],
                "ddr is already locked"
            );
            require(
                ownerOf(ddrId) == senderAddress,
                "Not owner of ddr"
            );
        _;
    }

    constructor(address _authAddress)
        ERC721Base("ddr", "DDR", _authAddress)
    {}
  
    function mint(
        bytes32 hashValue,
        string memory uri,
        address identity
    ) public returns (uint256) {
        _hashValue = keccak256(abi.encodePacked(_hashValue , hashValue));
        uint256 tokenId = super.mint(uri);
        _ddrHash[tokenId] = _hashValue;
        _ddrHistory[tokenId].push(tokenId);
        _DDRPatient[identity] = _hashValue;
        _isDDRLocked[tokenId -1] = true;
        _owner[tokenId] = identity;

        return tokenId;
    }

    function getDDRHistory(uint256 ddrId)
        public
        view
        returns (uint256[] memory)
    {
        return _ddrHistory[ddrId];
    }

    function getDDRofPatient(address _identity) public view returns(bytes32){
        return _DDRPatient[_identity];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owner[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function statusLockDDR(uint256 tokenId) public view returns(bool){
        return _isDDRLocked[tokenId];
    }

    function discloseApproval(uint256 ddrId, address _address) external override onlyPatient{
        _isDisclosable[ddrId][_address] = true;
    }

    function getDiscloseApproval(uint256 ddrId, address _address) external view override  onlyPatient returns(bool){
        return _isDisclosable[ddrId][_address];
    }

    function getHashValue(uint256 tokenId) external view override returns(bytes32){
        return _ddrHash[tokenId]; 
    }
}