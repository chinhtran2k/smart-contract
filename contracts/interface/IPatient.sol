// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPatient {
    event approval(address spender, uint256 tokenId);
    function consentDDRforClinic(
        uint256 DDRId, uint256 tokenId, address _address
    ) external;
    function getconsentDDR(uint256 DDRId, address _address) external view returns(bool);
    function getHashValue(uint256 tokenId) external view returns(bytes32);
}