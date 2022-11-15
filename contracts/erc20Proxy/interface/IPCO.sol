// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../enum/LevelLock.sol";

interface IPCO {
    function awardSubject(address sbAddress, LevelLock levelLock) external;
}   
