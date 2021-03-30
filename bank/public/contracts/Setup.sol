pragma solidity 0.4.24;

import "./Bank.sol";

contract WETH9 is ERC20Like {
    function deposit() public payable;
}

contract Setup {
    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Bank public bank;
    
    constructor() public payable {
        require(msg.value == 50 ether);
        
        bank = new Bank();
        
        weth.deposit.value(msg.value)();
        weth.approve(address(bank), uint(-1));
        bank.depositToken(0, address(weth), weth.balanceOf(address(this)));
    }
    
    function isSolved() external view returns (bool) {
        return weth.balanceOf(address(bank)) == 0;
    }
}
