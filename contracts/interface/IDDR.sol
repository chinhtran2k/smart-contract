// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDDR {
    // function setLockDDR(
    //     uint256[] memory DDRIds,
    //     address senderAddress
    // ) external;

    function discloseApproval(
        uint256 DDRId, address _address
    ) external;
    function getDiscloseApproval (uint256 DDRId, address _address) external view returns(bool);
    function getHashValue(uint256 tokenId) external view returns(bytes32);
}
