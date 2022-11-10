// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDDR {
    event approval(address spender, uint256 tokenId);

    function getShareApproval(uint256 DDRId, address _address)
        external
        view
        returns (bool);
}
