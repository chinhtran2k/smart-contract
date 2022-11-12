// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDDR {
    event ApprovalConsent(address Pharmacy, address Patient, uint256 tokenId);
    event DDRTokenLocked(uint256 tokenId);

    function getShareApproval(uint256 DDRId, address _address)
        external
        view
        virtual
        returns (bool);
}
