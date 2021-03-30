pragma solidity 0.7.0;

import "./Market.sol";

contract Setup {
    EternalStorageAPI public eternalStorage;
    CryptoCollectibles public token;
    CryptoCollectiblesMarket public market;
    
    constructor() payable {
        require(msg.value == 50 ether);
        
        // deploy our contracts
        eternalStorage = EternalStorageAPI(address(new EternalStorage(address(this))));
        token = new CryptoCollectibles();
        
        eternalStorage.transferOwnership(address(token));
        token.setEternalStorage(eternalStorage);
        
        market = new CryptoCollectiblesMarket(token, 1 ether, 1000);
        token.setMinter(address(market), true);
        
        // mint 4 founders tokens
        uint tokenCost = 5 ether;
        for (uint i = 0; i < 4; i++) {
            market.mintCollectibleFor{value: tokenCost}(address(bytes20(keccak256(abi.encodePacked(address(this), i)))));
            tokenCost += 5 ether;
        }
    }
    
    function isSolved() external view returns (bool) {
        return address(market).balance == 0;
    }
}
