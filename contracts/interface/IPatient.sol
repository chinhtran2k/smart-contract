// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPatient {
    event approval(address spender, uint256 tokenId);
    function consentDDRforClinic(
        uint256 DDRId, address identity, address _address
    ) external;
    function getConsentDDR(uint256 DDRId, address _address) external view returns(bool);
}