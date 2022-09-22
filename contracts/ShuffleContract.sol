// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./VerifyLibrary.sol";
import "./SimpleLibrary.sol";

contract ShuffleContract {
    using SimpleLibrary for *;
    using VerifyLibrary for *;

    uint256 activePlayers;
    uint256 totalPlayers;

    struct Player {
        address sigAddress;
        address currentOpponent;
        uint256 buyinAmount;
        uint256 depositAmount;
        uint256 buyinTime;
        bool isActive;
    }
    mapping(address => Player) players;

    event GameCreated(
        address indexed _creator,
        address indexed _opponent,
        uint256 _buyin
    );
    event GameStarted(
        address indexed _creator,
        address indexed _opponent,
        uint256 _buyin
    );
    event GameConceded(
        address indexed _winner,
        address indexed _loser,
        uint256 _buyin,
        uint256 _hands
    );

    receive() external payable {}

    function buyin(
        address _sigAddress,
        address _opponent,
        uint256 _buyinAmount
    ) external payable {
        uint256 _buyin;
        require(!players[msg.sender].isActive, "already active");
        if (players[_opponent].isActive) {
            require(players[_opponent].currentOpponent == msg.sender);
            _buyin = players[_opponent].buyinAmount;
        } else {
            _buyin = _buyinAmount;
        }
        require(msg.value >= ((_buyin * 12) / 10), "insufficient deposit");
        Player memory player = Player(
            _sigAddress,
            _opponent,
            _buyin,
            msg.value,
            block.timestamp,
            true
        );
        players[msg.sender] = player;
        if (players[_opponent].currentOpponent == msg.sender) {
            emit GameStarted(_opponent, msg.sender, msg.value);
        } else {
            emit GameCreated(msg.sender, _opponent, msg.value);
        }
        totalPlayers++;
        activePlayers++;
    }

    function concede(uint256 _hands) external {
        require(players[msg.sender].isActive);

        // declare variables for final transfer
        address _opponent = players[msg.sender].currentOpponent;
        uint256 _buyin = players[msg.sender].buyinAmount;
        uint256 _remainder = players[msg.sender].depositAmount - _buyin;
        uint256 _transferAmount = _buyin * 2 + _remainder;

        // transfer winnings to winner and deposit amount back to conceding player
        payable(_opponent).transfer(_transferAmount);
        payable(msg.sender).transfer(_remainder);

        // reset player accounts to 0
        Player memory _null_player_one = Player(
            address(0),
            address(0),
            0,
            0,
            0,
            false
        );
        Player memory _null_player_two = Player(
            address(0),
            address(0),
            0,
            0,
            0,
            false
        );
        players[_opponent] = _null_player_one;
        players[msg.sender] = _null_player_two;
        activePlayers = activePlayers - 2;
        // emit final event announcing the game as completed
        emit GameConceded(_opponent, msg.sender, _buyin, _hands);
    }

    function getSigKey(address _userAddress)
        external
        view
        returns (address _sigAddress)
    {
        require(players[msg.sender].isActive);
        _sigAddress = players[_userAddress].sigAddress;
    }
}
