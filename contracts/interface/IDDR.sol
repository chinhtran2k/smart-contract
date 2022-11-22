// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDDR {
    event MintedDDR(uint256 tokenId,
        string ddrRawId, 
        string ddrPatientRawId,
        bytes32 hashedData,
        bytes32 hashValue,
        address patientDID);
    event DDRTokenLocked(uint256 tokenId);
    event ApprovalShareDDR(address patientDID, uint256 tokenId);
    event ApprovalDisclosureConsentDDR(address patientDID, address providerDID, uint256[] ddrTokenIds);
}