pragma solidity 0.4.24;

contract ERC20Like {
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function approve(address, uint) public;
    
    function decimals() public view returns (uint8);
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function allowance(address owner, address spender) public view returns (uint);

    function balanceOf(address) public view returns (uint);
    function totalSupply() public view returns (uint);
}