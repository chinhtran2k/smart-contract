// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../enum/AuthType.sol";

interface IAuthenticator {
    function checkAuth(address _address) external view returns (AuthType);
}
