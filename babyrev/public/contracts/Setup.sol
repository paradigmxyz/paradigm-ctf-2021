pragma solidity 0.4.24;

import "private/Challenge.sol";

interface ChallengeInterface {
    function solved() public view returns (bool);
}

contract Setup {
    ChallengeInterface public challenge;
    
    constructor() public payable {
        require(msg.value == 50 ether);
        
        challenge = ChallengeInterface(address(new Challenge()));
    }
    
    function isSolved() public view returns (bool) {
        return challenge.solved();
    }
}