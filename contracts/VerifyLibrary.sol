// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library VerifyLibrary {
    function verifySig(
        string memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address _signer) {
        // message header --- fill in length later
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(_message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            // non-zero digit or non-leading zero digit
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;

            // convert the digit to its asciii representation (man ascii)
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 _check = keccak256(abi.encodePacked(header, _message));
        _signer = ecrecover(_check, _v, _r, _s);
    }

    function verifyHash(
        bytes32 _hash,
        string memory _message,
        string memory _salt
    ) internal pure returns (bool _verified) {
        _verified = keccak256(abi.encodePacked(_message, _salt)) == _hash;
    }

    function parseInt(string memory _string) internal pure returns (uint256) {
        bytes memory _bytes = bytes(_string);
        uint256 result = 0;
        for (uint8 i = 0; i < _bytes.length; i++) {
            result = result * 10 + (uint8(_bytes[i]) - 48);
        }
        return result;
    }

    function verifyProof(
        bytes32 _leaf,
        bytes32[] memory _proof,
        uint256[] memory _position,
        bytes32 _root
    ) internal pure returns (bool _verified) {
        bytes32 _data = _leaf;
        for (uint256 i = 0; i < _proof.length; i++) {
            if (_position[i] == 0) {
                _data = keccak256(abi.encodePacked(_data, _proof[i]));
            } else {
                _data = keccak256(abi.encodePacked(_proof[i], _data));
            }
        }
        _verified = (_data == _root);
    }
}
