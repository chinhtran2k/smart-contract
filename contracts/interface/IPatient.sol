// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPatient {
    event approval(address spender, uint256 tokenId);
    event PatientLockTokenMinted(uint256 patientTokenId, address patientDID, bytes32 rootNodeId, bytes32 rootHash);
    event PharmacyLockTokenMinted(uint256 pharmacyTokenId, address pharmacyDID, bytes32 rootNodeId, bytes32 rootHash);
}