// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library SimpleLibrary {
    function parseCardValue(uint256 _cardValue)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 _cardSuit = _cardValue % 4;
        if (_cardSuit == 0) {
            _cardSuit = 4;
        }
        uint256 _cardNumber = (_cardValue - _cardSuit) / 4 + 1;
        return (_cardNumber, _cardSuit);
    }

    function parseAllCards(uint256[7] memory _cards)
        internal
        pure
        returns (uint256[7] memory, uint256[7] memory)
    {
        uint256[7] memory _cardArr;
        uint256[7] memory _suitArr;
        for (uint256 i = 0; i < 7; i++) {
            (uint256 _cardNumber, uint256 _cardSuit) = parseCardValue(
                _cards[i]
            );
            _cardArr[i] = _cardNumber;
            _suitArr[i] = _cardSuit;
        }
        return (_cardArr, _suitArr);
    }

    function checkPairs(uint256[7] memory _cards)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256[7] memory _allCards, ) = parseAllCards(_cards);
        uint256 _counterOne = 0;
        uint256 _counterTwo = 0;
        uint256 _pairValueOne = 0;
        uint256 _pairValueTwo = 0;
        for (uint256 i = 0; i < 6; i++) {
            if (
                _allCards[i] == _pairValueOne || _allCards[i] == _pairValueTwo
            ) {
                continue;
            }
            for (uint256 j = i + 1; j < 7; j++) {
                if (_allCards[i] == _allCards[j]) {
                    if (_counterOne == 0) {
                        _counterOne++;
                        _pairValueOne = _allCards[j];
                    } else {
                        if (_pairValueOne == _allCards[j]) {
                            _counterOne++;
                        } else {
                            if (_counterTwo == 0) {
                                _counterTwo++;
                                _pairValueTwo == _allCards[j];
                            } else {
                                if (_pairValueTwo == _allCards[j]) {
                                    _counterTwo++;
                                }
                            }
                        }
                    }
                }
            }
        }
        return (_counterOne + 1, _pairValueOne, _counterTwo + 1, _pairValueTwo);
    }

    function checkStraight(uint256[7] memory _cards)
        internal
        pure
        returns (bool, uint256)
    {
        (uint256[7] memory _allCards, ) = parseAllCards(_cards);
        bool _isStraight = false;
        uint256 _highCard = 0;
        for (uint256 i = 0; i < 7; i++) {
            uint256 _upCheck = _allCards[i];
            uint256 _upwardsCounter = 1;
            uint256 _downCheck = _allCards[i];
            uint256 _downwardsCounter = 1;
            for (uint256 j = 0; j < 7; j++) {
                if (i == j) {
                    continue;
                }
                if (_allCards[j] == (_upCheck + 1)) {
                    _upwardsCounter++;
                    _upCheck++;
                    _highCard = _upCheck;
                }
                if (_allCards[j] == (_downCheck - 1)) {
                    _downwardsCounter++;
                    _downCheck--;
                }
                if (_upwardsCounter + _downwardsCounter >= 5) {
                    _isStraight = true;
                }
            }
        }
        return (_isStraight, _highCard);
    }

    function checkFlush(uint256[7] memory _cards)
        internal
        pure
        returns (
            bool,
            bool,
            bool
        )
    {
        (, uint256[7] memory _allSuits) = parseAllCards(_cards);
        uint256 _counter = 1;
        uint256 _suit = _allSuits[0];
        for (uint256 i = 1; i < 7; i++) {
            if (_allSuits[i] == _suit) {
                _counter++;
            }
        }
        if (_counter < 5 && _allSuits[1] != _suit) {
            _counter = 1;
            _suit = _allSuits[1];
            for (uint256 j = 2; j < 7; j++) {
                if (_allSuits[j] == _suit) {
                    _counter++;
                }
            }
        }
        if (
            _counter < 5 &&
            _allSuits[2] != _suit &&
            _allSuits[2] != _allSuits[0]
        ) {
            _counter = 1;
            _suit = _allSuits[2];
            for (uint256 z = 3; z < 7; z++) {
                if (_allSuits[z] == _suit) {
                    _counter++;
                }
            }
        }
        if (_counter >= 5) {
            return (true, _allSuits[0] == _suit, _allSuits[1] == _suit);
        } else {
            return (false, false, false);
        }
    }
}
