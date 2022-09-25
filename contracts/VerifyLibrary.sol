// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library VerifyLibrary {
    function prepHashForSig(string memory _message)
        internal
        pure
        returns (bytes32 _ethHash)
    {
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
        _ethHash = keccak256(abi.encodePacked(header, _message));
    }

    function verifyHash(
        bytes32 _hash,
        string memory _message,
        string memory _salt
    ) internal pure returns (bool _verified) {
        _verified = keccak256(abi.encodePacked(_message, _salt)) == _hash;
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

    function proveIncHash(
        address _oppSigKey,
        bytes32 _incHash,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _merkleRoot,
        bytes32[] memory _proof,
        uint256[] memory _proofPosition
    ) internal pure returns (bool _proven) {
        require(
            _oppSigKey == ecrecover(_merkleRoot, _sigV, _sigR, _sigS),
            "unable to validate signature"
        );
        require(
            verifyProof(_incHash, _proof, _proofPosition, _merkleRoot),
            "unable to verify merkle proof"
        );
        _proven = true;
    }

    function proveIncString(
        address _oppSigKey,
        string memory _incString,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _merkleRoot,
        bytes32[] memory _proof,
        uint256[] memory _proofPosition
    ) internal pure returns (bool _proven) {
        bytes32 _ethHash = prepHashForSig(_incString);
        require(
            _oppSigKey == ecrecover(_ethHash, _sigV, _sigR, _sigS),
            "unable to verify signature"
        );
        require(
            verifyProof(_ethHash, _proof, _proofPosition, _merkleRoot),
            "unable to verify merkle proof"
        );
        _proven = true;
    }

    function proveHiddenString(
        address _oppSigKey,
        string memory _hiddenString,
        string memory _salt,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes32 _merkleRoot,
        bytes32[] memory _proof,
        uint256[] memory _proofPosition
    ) internal pure returns (bool _proven) {
        string memory _fullString = string.concat(_hiddenString, _salt);
        _proven = proveIncString(
            _oppSigKey,
            _fullString,
            _sigV,
            _sigR,
            _sigS,
            _merkleRoot,
            _proof,
            _proofPosition
        );
    }

    function verifyDoubleHashed(
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address _signer) {
        bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _hashedEthMessage = keccak256(abi.encodePacked(_prefix, _hash));
        _signer = ecrecover(_hashedEthMessage, _v, _r, _s);
    }
}
