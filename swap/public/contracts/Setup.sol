pragma solidity 0.4.24;

import "public/Swap.sol";

contract UniswapV2RouterLike {
    function swapExactETHForTokens(uint amountOutMin, address[] memory path, address to, uint deadline)
        public
        payable
        returns (uint[] memory amounts);
}

contract Setup {
    StableSwap public swap;
    uint public value;
    
    constructor() public payable {
        swap = new StableSwap();
        
        UniswapV2RouterLike router = UniswapV2RouterLike(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);
        
        ERC20Like[4] memory tokens = [
            ERC20Like(0x6B175474E89094C44Da98b954EedeAC495271d0F),
            ERC20Like(0x0000000000085d4780B73119b644AE5ecd22b376),
            ERC20Like(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            ERC20Like(0xdAC17F958D2ee523a2206206994597C13D831ec7)
        ];
        
        uint[] memory amounts = new uint[](4);
        
        for (uint i = 0; i < 4; i++) {
            swap.addCollateral(tokens[i]);
            
            address[] memory path = new address[](2);
            path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            path[1] = address(tokens[i]);
            
            router.swapExactETHForTokens.value(100 ether)(0, path, address(this), uint(-1));
            
            tokens[i].approve(address(swap), uint(-1));
            amounts[i] = tokens[i].balanceOf(address(this));
        }
        
        swap.mint(amounts);

        value = swap.totalValue();
    }

    function isSolved() public view returns (bool) {
        return swap.totalValue() < value / 100;
    }
}