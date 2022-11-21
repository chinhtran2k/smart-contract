// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../enum/AuthType.sol";
import "../DID/ClaimHolder.sol";

interface IAuthenticator {
    // event CreatedAuthentication(address identity, AuthType _authType);

    function checkAuth(ClaimHolder _address, AuthType _authType) external view returns (bool);
}
