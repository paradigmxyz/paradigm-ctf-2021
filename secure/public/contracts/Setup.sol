pragma solidity 0.5.12;

import "./Wallet.sol";

contract WETH9 is ERC20Like {
    function deposit() public payable;
}

contract Setup {
    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint public constant WANT = 50 ether;

    Wallet public wallet;

    constructor() public payable {
        require(msg.value == WANT);

        address tokenModule = address(new TokenModule());

        wallet = new Wallet();
        wallet.allowModule(tokenModule);

        WETH.deposit.value(msg.value)();
        WETH.approve(address(wallet), uint(-1));

        wallet.execModule(tokenModule, abi.encodeWithSelector(TokenModule(0x00).deposit.selector, WETH, address(this), msg.value));
    }

    function isSolved() public view returns (bool) {
        return WETH.balanceOf(address(this)) == WANT;
    }
}