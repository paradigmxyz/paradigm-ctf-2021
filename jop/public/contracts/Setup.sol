pragma solidity 0.7.6;

import "private/Challenge.sol";

interface ChallengeInterface is IERC20 {
    function buyTokens() external payable;
    
    function owner() external view returns (address);
}

contract Setup {
    ChallengeInterface public challenge;
    
    constructor() public payable {
        require(msg.value == 50 ether);
        
        challenge = ChallengeInterface(address(new Challenge(990, 1010)));
        challenge.buyTokens{value: msg.value}();
    }
    
    function isSolved() public view returns (bool) {
        return  challenge.owner() == 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD &&
                challenge.balanceOf(address(this)) == 0 &&
                address(challenge).balance == 0;
    }
}