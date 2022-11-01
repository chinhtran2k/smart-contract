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

    // function setAccessHRAddress(address _address) external ;
    // function getAccessHRAddress() external view returns(address);
    function getDiscloseApproval (uint256 prescriptionId, address _address) external view returns(bool);
    function getHashValue(uint256 tokenId) external view returns(bytes32);
    // function getListId() external view returns(uint256[] memory);
}
