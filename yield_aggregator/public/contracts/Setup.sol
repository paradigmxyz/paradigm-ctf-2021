pragma solidity 0.8.0;

import "./YieldAggregator.sol";

// dumb bank with 0% interest rates
contract MiniBank is Protocol {
    ERC20Like public override underlying = ERC20Like(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;

    function mint(uint256 amount) public override {
        require(underlying.transferFrom(msg.sender, address(this), amount));
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
    }

    function burn(uint256 amount) public override {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        require(underlying.transfer(msg.sender, amount));
    }

    function balanceUnderlying() public override view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function rate() public override view returns (uint256) {
        return 1;
    }
}

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract Setup {
    YieldAggregator public aggregator;
    MiniBank public bank;
    WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor() payable {
        require(msg.value == 100 ether);
        bank = new MiniBank();

        aggregator = new YieldAggregator();

        weth.deposit{value: msg.value}();
        weth.approve(address(aggregator), type(uint256).max);

        address[] memory _tokens = new address[](1);
        _tokens[0] = address(weth);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 50 ether;

        // we deposit 50 weth to the system
        aggregator.deposit(Protocol(address(bank)), _tokens, _amounts);
    }

    function isSolved() public view returns (bool) {
        return weth.balanceOf(address(aggregator)) == 0 &&
            weth.balanceOf(address(bank)) == 0;
    }
}
