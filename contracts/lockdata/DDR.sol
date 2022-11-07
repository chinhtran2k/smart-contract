// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "../utils/ERC721Base.sol";
import "../utils/Authenticator.sol";
import "../interface/IDDR.sol";


 contract DDR is ERC721Base, IDDR{
  event UpdateDDR(uint256 _Id, bytes32 _hashValue, string _uri);
  event SetLockDDR(uint256[] _listIds, address _address);
  mapping(uint256 => uint256[]) private _DDRHistory;
  mapping(uint256 => bytes32) public _DDRHash;
  mapping(uint256 => bool) private _isDDRHistory;
  mapping(uint256 => bool) private _isDDRLocked;
  mapping(uint256 => mapping(address => bool))  private _isDisclosable;
  mapping(uint256 => address) public _patientAddress;  

  modifier _validDDRList(
        uint256[] memory DDRIds,
        address senderAddress
    ) {
        for (uint256 i = 0; i < DDRIds.length; i++) {
            require(
                !_isDDRLocked[DDRIds[i]],
                "DDR is already locked"
            );
            require(
                ownerOf(DDRIds[i]) == senderAddress,
                "Not owner of DDR"
            );
            require(
                !_isDDRHistory[DDRIds[i]],
                "Cannot lock DDR History"
            );
        }
        _;
    }

    constructor(address _authAddress)
        ERC721Base("DRR", "DRR", _authAddress)
    {}
  
    function mint(
        bytes32 hashValue,
        string memory uri
    ) public onlyPatients returns (uint256) {
        uint256 tokenId = super.mint(uri);
        _DDRHash[tokenId] = hashValue;
        _DDRHistory[tokenId].push(tokenId);
        _isDDRHistory[tokenId] = false;
        return tokenId;
    }

    // function getAddress(uint256 tokenId)public view returns(address){
    //     return _patientAddress[tokenId];
    // }

    function updateDDR(
        uint256 DDRId,
        bytes32 hashValue,
        string memory uri
        // string memory data
    ) public onlyPatients {
        require(
            !_isDDRHistory[DDRId],
            "Cannot update DDR History"
        );

        require(!_isDDRLocked[DDRId], "DDR is locked");

        require(
            ownerOf(DDRId) == _msgSender(),
            "Not the owner of the DDR"
        );
        uint256 newDDRId = super.mint(uri);
        _DDRHash[newDDRId] = hashValue;
        _DDRHistory[newDDRId].push(newDDRId);
        _isDDRHistory[newDDRId] = true;
        _DDRHistory[DDRId].push(newDDRId);
        emit UpdateDDR(DDRId, hashValue, uri);
    }

    function getDDRHistory(uint256 DDRId)
        public
        view
        returns (uint256[] memory)
    {
        return _DDRHistory[DDRId];
    }

    function checkDataIntegrity(uint256 DDRId, bytes32 hashValue)
        public
        view
        returns (bool)
    {
        uint256 lastDDRId = _DDRHistory[DDRId][
            _DDRHistory[DDRId].length - 1
        ];

        return _DDRHash[lastDDRId] == hashValue;
    }

    function setLockDDR(
        uint256[] memory DDRIds,
        address senderAddress
    ) external override _validDDRList(DDRIds, senderAddress) {
        for (uint256 i = 0; i < DDRIds.length; i++) {
            _isDDRLocked[DDRIds[i]] = true;
        }
        emit SetLockDDR(DDRIds, senderAddress);
    }

    // function setAccessHRAddress(address _address) external override onlyHealthRecord {
    //     healthRecordContractAddress = _address;
    // } 
    

    // function getAccessHRAddress() external view override returns(address){
    //     return healthRecordContractAddress;
    // } 

    function discloseApproval(uint256 DDRId, address _address) external override onlyPatients{
        _isDisclosable[DDRId][_address] = true;
    }

    function getDiscloseApproval(uint256 DDRId, address _address) external view override  onlyPatients returns(bool){
        return _isDisclosable[DDRId][_address];
    }

    // modifier onlyHealthRecordAddress(){
    //     require(msg.sender == healthRecordContractAddress, "Only this healthRecordAddress can do this");
    //     _;
    // }

    function getHashValue(uint256 tokenId) external view override returns(bytes32){
        return _DDRHash[tokenId]; 
    }
}
