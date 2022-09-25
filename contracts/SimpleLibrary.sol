// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library SimpleLibrary {
    // only necessary within this library -- used in parseAllCards()
    function parseCardValue(uint8 _cardValue)
        internal
        pure
        returns (uint8 _value)
    {
        uint8 _cardSuit = _cardValue % 4;
        if (_cardSuit == 0) {
            _cardSuit = 4;
        }
        _value = (_cardValue - _cardSuit) / 4 + 1;
    }

    // only necessary within this library
    function parseBothCardValues(uint8[2] memory _cards)
        internal
        pure
        returns (uint8, uint8)
    {
        uint8 _cardVal = parseCardValue(_cards[0]);
        uint8 _oppCardVal = parseCardValue(_cards[1]);

        return (_cardVal, _oppCardVal);
    }

    function parseInt(string memory _string) internal pure returns (uint256) {
        bytes memory _bytes = bytes(_string);
        uint256 result = 0;
        for (uint8 i = 0; i < _bytes.length; i++) {
            result = result * 10 + (uint8(_bytes[i]) - 48);
        }
        return result;
    }
}
