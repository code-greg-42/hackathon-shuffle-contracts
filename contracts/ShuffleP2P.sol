// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./VerifyLibrary.sol";
import "./SimpleLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ShuffleP2P is ERC20 {
    using SimpleLibrary for *;
    using VerifyLibrary for *;

    struct ShuffleInfo {
        uint256 activePlayers;
        uint256 totalPlayers;
        uint256 totalBuyinsAtPlay;
        uint256 supplyInCirculation;
        uint256 adAuctionClosingTime;
    }

    ShuffleInfo public shuffleInfo;
    IERC20 shuffleCoin = IERC20(address(this));

    struct Player {
        address sigAddress;
        address currentOpponent;
        uint256 buyinAmount;
        uint256 betAmount;
        bool isActive;
    }
    mapping(address => Player) players;

    struct Advertiser {
        address ethAddr;
        bytes32 ipfsCid;
        uint256 bidAmount;
        uint256 bidTimestamp;
    }

    struct IncompleteGame {
        address posterAddr;
        address opponentAddr;
        uint256 handNum;
        uint256 posterStack;
        uint256 opponentStack;
        uint256 timestamp;
        bool firstToAct;
        bool completed;
        bool exists;
    }

    mapping(address => IncompleteGame) incompleteGames;

    event IncompleteGamePosted(
        address indexed poster,
        address indexed opponent,
        uint256 handNum,
        uint256 posterStack,
        uint256 oppStack,
        uint256 timestamp,
        bool firstToAct
    );

    bytes32 public currentAdvertisement;
    Advertiser public adHighestBidder;

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

    uint256 constant _initial_supply = 1000000000 * (10**18);

    constructor() ERC20("ShuffleP2P", "SHFL") {
        _mint(address(this), _initial_supply);
        shuffleInfo.adAuctionClosingTime = block.timestamp + 4 weeks;
    }

    receive() external payable {}

    function buyin(
        address _sigAddress,
        address _opponent,
        uint256 _buyinAmount,
        uint256 _betAmount
    ) external payable {
        uint256 _buyin;
        uint256 _betNum;
        require(!players[msg.sender].isActive, "already active");
        if (players[_opponent].isActive) {
            require(players[_opponent].currentOpponent == msg.sender);
            _buyin = players[_opponent].buyinAmount;
            _betNum = players[_opponent].betAmount;
        } else {
            _buyin = _buyinAmount;
            _betNum = _betAmount;
        }
        require(msg.value >= _buyin);
        Player memory player = Player(
            _sigAddress,
            _opponent,
            _buyin,
            _betNum,
            true
        );
        players[msg.sender] = player;
        if (players[_opponent].currentOpponent == msg.sender) {
            emit GameStarted(_opponent, msg.sender, msg.value);
        } else {
            emit GameCreated(msg.sender, _opponent, msg.value);
        }
        shuffleInfo.totalBuyinsAtPlay += _buyin;
        shuffleInfo.totalPlayers++;
        shuffleInfo.activePlayers++;
    }

    function concedeAll(uint256 _hands) external {
        require(players[msg.sender].isActive);

        // declare variables for final transfer
        address _opponent = players[msg.sender].currentOpponent;
        uint256 _buyin = players[msg.sender].buyinAmount;
        // transfer winnings to winner and deposit amount back to conceding player
        payable(_opponent).transfer(_buyin * 2);
        shuffleInfo.totalBuyinsAtPlay -= _buyin * 2;

        // reset player accounts to 0
        players[_opponent] = Player(address(0), address(0), 0, 0, false);
        players[msg.sender] = Player(address(0), address(0), 0, 0, false);
        shuffleInfo.activePlayers -= 2;
        // emit final event announcing the game as completed
        emit GameConceded(_opponent, msg.sender, _buyin, _hands);
    }

    function submitAdBid(bytes32 _ipfsCid) external payable {
        require(msg.value > adHighestBidder.bidAmount, "bid too low!");
        require(
            block.timestamp < shuffleInfo.adAuctionClosingTime,
            "too late!"
        );
        if (adHighestBidder.ethAddr != address(0)) {
            payable(adHighestBidder.ethAddr).transfer(
                adHighestBidder.bidAmount
            );
        }
        adHighestBidder = Advertiser(
            msg.sender,
            _ipfsCid,
            msg.value,
            block.timestamp
        );
    }

    function pushAdPurchase() external {
        require(players[msg.sender].isActive);
        require(block.timestamp > shuffleInfo.adAuctionClosingTime);
        currentAdvertisement = adHighestBidder.ipfsCid;
        adHighestBidder = Advertiser(address(0), 0, 0, 0);
        shuffleInfo.adAuctionClosingTime = block.timestamp + 4 weeks;
        // reward submitter
        shuffleCoin.transfer(msg.sender, 1000 * (10**18));
        shuffleInfo.supplyInCirculation += 1000 * (10**18);
    }

    function tokenTurnIn() external {
        uint256 _userBalance = shuffleCoin.balanceOf(msg.sender);
        require(_userBalance > 0);
        uint256 _conversionRate = shuffleInfo.supplyInCirculation /
            _userBalance;
        uint256 _rewardAmount = address(this).balance / _conversionRate;
        shuffleInfo.supplyInCirculation -= _userBalance;
        shuffleCoin.transfer(msg.sender, _rewardAmount);
    }

    function getSigKey(address _userAddress)
        public
        view
        returns (address _sigAddress)
    {
        require(players[msg.sender].isActive);
        _sigAddress = players[_userAddress].sigAddress;
    }

    // if you would like to receive winnings for the most recent hand, this must be done within about 8.5 minutes from receiving the signature
    function postIncompleteGame(
        string[6] memory _stats,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bool _disputeExisting
    ) external {
        address _opponent = players[msg.sender].currentOpponent;
        bytes32 _messageHash = keccak256(
            abi.encodePacked(
                _stats[0],
                _stats[1],
                _stats[2],
                _stats[3],
                _stats[4],
                _stats[5]
            )
        );
        require(
            _messageHash.verifyDoubleHashed(_v, _r, _s) ==
                players[_opponent].sigAddress,
            "unable to verify signature"
        );
        bool _firstToAct;
        if (
            keccak256(abi.encodePacked(_stats[5])) ==
            keccak256(abi.encodePacked("firsttoact"))
        ) {
            _firstToAct = true;
        } else {
            _firstToAct = false;
        }
        if (_disputeExisting) {
            disputeExisting(_stats[2], _firstToAct);
        } else {
            calculateAndPost(_stats, _firstToAct);
        }
    }

    function calculateAndPost(string[6] memory _stats, bool _firstToAct)
        internal
    {
        address _opponent = players[msg.sender].currentOpponent;
        uint256 _handNum = _stats[2].parseInt();
        uint256 _myStack = _stats[4].parseInt();
        uint256 _oppStack = _stats[3].parseInt();

        uint256 _block_num_one = _stats[0].parseInt();
        uint256 _block_num_two = _stats[1].parseInt();
        uint256 _card_one = (uint256(blockhash(_block_num_one))) % 13;
        uint256 _card_two = (uint256(blockhash(_block_num_two))) % 13;

        if (_card_one > _card_two) {
            _oppStack += players[msg.sender].betAmount;
            _myStack -= players[msg.sender].betAmount;
        }
        if (_card_one < _card_two) {
            _oppStack -= players[msg.sender].betAmount;
            _myStack += players[msg.sender].betAmount;
        }

        incompleteGames[msg.sender] = IncompleteGame(
            msg.sender,
            _opponent,
            _handNum,
            _myStack,
            _oppStack,
            block.timestamp,
            _firstToAct,
            false,
            true
        );
        emit IncompleteGamePosted(
            msg.sender,
            _opponent,
            _handNum,
            _myStack,
            _oppStack,
            block.timestamp,
            _firstToAct
        );
    }

    function disputeExisting(string memory _hand, bool _firstToAct) internal {
        require(players[msg.sender].isActive);
        address _opponent = players[msg.sender].currentOpponent;
        require(incompleteGames[_opponent].exists);
        require(incompleteGames[_opponent].completed == false);
        require(
            block.timestamp - incompleteGames[_opponent].timestamp <= 10 minutes
        );

        uint256 _handNum = _hand.parseInt();
        uint256 _handNumsAhead = _handNum - incompleteGames[_opponent].handNum;

        if (incompleteGames[_opponent].firstToAct && _handNumsAhead > 1) {
            payable(msg.sender).transfer(players[msg.sender].buyinAmount * 2);
        }
        if (
            incompleteGames[_opponent].firstToAct == false && _handNumsAhead > 0
        ) {
            payable(msg.sender).transfer(players[msg.sender].buyinAmount * 2);
        } else {
            payable(_opponent).transfer(players[msg.sender].buyinAmount * 2);
        }
    }

    function completePayout(address _poster) external {
        require(
            block.timestamp - incompleteGames[_poster].timestamp > 10 minutes
        );
        payable(_poster).transfer(incompleteGames[_poster].posterStack);
        payable(incompleteGames[_poster].opponentAddr).transfer(
            incompleteGames[_poster].opponentStack
        );
        incompleteGames[_poster].completed = true;
        incompleteGames[_poster].exists = false;
        // reward self
        shuffleCoin.transfer(msg.sender, 100 * (10**18));
    }
}
