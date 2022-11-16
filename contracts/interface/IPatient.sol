// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPatient {
    event PatientLockTokenMinted(uint256 patientTokenId, address patientDID, bytes32 rootNodeId, bytes32 rootHash);
}