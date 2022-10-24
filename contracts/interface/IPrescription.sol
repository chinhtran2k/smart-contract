// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrescription {
    function setLockPrescription(
        uint256[] memory PrescriptionIds,
        address senderAddress
    ) external;

    function discloseApproval(
        uint256 prescriptionId, address _address
    ) external;

    function setHealthRecordAddress(address _address) external ;
    function getHealthRecordAddress() external view returns(address);
    function getDiscloseApproval (uint256 prescriptionId, address _address) external view returns(bool);
}
