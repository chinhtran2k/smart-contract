// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrescription {
    function setLockPrescription(
        uint256[] memory PrescriptionIds,
        address senderAddress
    ) external;
}
