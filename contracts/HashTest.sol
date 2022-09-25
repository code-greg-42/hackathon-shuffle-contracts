// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract HashTest {
    function testHash(
        uint256[2] memory _nums,
        string[4] memory _actions,
        bytes32 _compareHash
    ) external view returns (bool _hashCompare) {
        bytes32 _block_one_hash = blockhash(_nums[0]);
        bytes32 _block_two_hash = blockhash(_nums[1]);
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _block_one_hash,
                _block_two_hash,
                _actions[0],
                _actions[1],
                _actions[2],
                _actions[3]
            )
        );
        _hashCompare = (_hash == _compareHash);
    }
}
