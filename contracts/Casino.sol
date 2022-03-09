pragma solidity 0.4.22;

contract Casino {

    address public owner;
    uint public minimumBet;
    uint public totalBet;
    uint public numberOfBets;
    uint public maxAmoutOfBets = 100;
    address[] public players;

    struct Player {
        uint amountBet;
        uint numberSelected;
    }

    // player to user info
    mapping(address => Player) public playerInfo;

    // Set creator of contract as owner
    constructor(uint _minimumBet) public {
        owner = msg.sender;
        if(_minimumBet != 0)
            minimumBet = _minimumBet;
    }

    function kill() public {
        if(msg.sender == owner)
            selfdestruct(owner);
    }

    // Fallback function in case someone sends ether to the contract 
    // will be distributed in each game
    function() public payable {}

    // A player can only play once per game
    function checkPlayerExists(address player) public view returns(bool) {
        for(uint i=0; i<players.length; i++) {
            if(players[i] == player)
                return true;
        }

        return false;
    }

    // Reset the game
    function resetData() private {
        players.length = 0;
        totalBet = 0;
        numberOfBets = 0;
    }

    // Payout the winners and reset the game
    function distributePrizes(uint winningNumber) public {
        // Create temp array in memory
        address[100] memory winners;
        uint count = 0;

        for(uint i=0; i<players.length; i++) {
            address playerAddress = players[i];
            if(playerInfo[playerAddress].numberSelected == winningNumber) {
                winners[count] = playerAddress;
                count++;
            }

            delete playerInfo[playerAddress];
        }

        // Winners' pot is split amongst the victors
        uint winnerAmountEth = totalBet / winners.length;

        // Send ETH to winners
        for(uint j=0; j<count; j++) {
            if(winners[j] != address(0)) {
                // Check that the address is not empty
                winners[j].transfer(winnerAmountEth);
            }
        }

        resetData();
    }

    // Generates a number between 1 and 10 that will be the winner
    function generateNumberWinner() public {
        uint winningNumber = block.number % 10 + 1; // This is not secure
        distributePrizes(winningNumber);
    }

    // Number has to be between 1 and 10 inclusive
    function bet(uint numberSelected) public payable {
        require(!checkPlayerExists(msg.sender));
        require(numberSelected >=1 && numberSelected <= 10);
        require(msg.value >= minimumBet);

        playerInfo[msg.sender] = Player(msg.value, numberSelected);
        numberOfBets++;
        players.push(msg.sender);
        totalBet += msg.value;

        // Check if this is the last bet
        if(numberOfBets >= maxAmoutOfBets)
            generateNumberWinner();
    }
}