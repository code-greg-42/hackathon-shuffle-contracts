// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./VerifyLibrary.sol";
import "./SimpleLibrary.sol";

contract ShuffleContract {
    using SimpleLibrary for *;
    using VerifyLibrary for *;
}
