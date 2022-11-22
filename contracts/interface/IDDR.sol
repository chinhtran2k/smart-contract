// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDDR {
    event MintedDDR(uint256 tokenId,
        string DDRRawId, 
        string DDRPatientRawId,
        bytes32 hashedData,
        bytes32 hashValue,
        address Patient);
    event DDRTokenLocked(uint256 tokenId);
    event ApprovalShareDDR(address Patient, uint256 tokenId);
    event ApprovalDisclosureConsentDDR(address Patient, address Provider, uint256[] ddrTokenIds);
}
