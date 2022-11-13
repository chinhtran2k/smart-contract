// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDDR {
    event MintedDDR(string DDRRawId, 
        bytes32 hashedData,
        bytes32 hashValue,
        address Pharmacy,
        address Patient);
    event DDRTokenLocked(uint256 tokenId);
    event ApprovalShareDDR(address Pharmacy, address Patient, uint256 tokenId);
    event ApprovalDisclosureConsentDDR(address Patient, address Hospital, uint256[] ddrTokenIds);
}
