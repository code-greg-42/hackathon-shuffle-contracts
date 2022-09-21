// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./VerifyLibrary.sol";

contract LibTest {
    using VerifyLibrary for *;

    function verifyKeccakHash(
        bytes32 _hash,
        string memory _message,
        string memory _salt
    ) internal pure returns (bool _verified) {
        _verified = _hash.verifyHash(_message, _salt);
    }

    function verifyStringSig(
        address _verifiedSigner,
        string memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool _verified) {
        _verified = (_verifiedSigner == _message.verifySig(_v, _r, _s));
    }

    function verifyHashSig(
        address _verifiedSigner,
        bytes32 _messageHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool _verified) {
        _verified = (_verifiedSigner == ecrecover(_messageHash, _v, _r, _s));
    }

    function parseUint256(string memory _string)
        internal
        pure
        returns (uint256 _result)
    {
        _result = _string.parseInt();
    }

    function TestFunction(
        bytes32 _hash,
        string memory _message,
        string memory _salt,
        string memory _stringTest,
        uint256 _uintTest
    ) public pure returns (bool _success) {
        require(verifyKeccakHash(_hash, _message, _salt), "incorrect hash");
        uint256 _tempUint = parseUint256(_stringTest);
        _success = (_tempUint == _uintTest);
    }
}
