pragma solidity 0.5.12;

contract ERC20Like {
    function transfer(address dst, uint qty) public returns (bool);
    function transferFrom(address src, address dst, uint qty) public returns (bool);
    function approve(address dst, uint qty) public returns (bool);
    
    function balanceOf(address who) public view returns (uint);
}

contract TokenModule {
    function deposit(ERC20Like token, address from, uint amount) public {
        token.transferFrom(from, address(this), amount);
    }

    function withdraw(ERC20Like token, address to, uint amount) public {
        token.transfer(to, amount);
    }
}

contract Wallet {
    address public owner = msg.sender;
    
    mapping(address => bool) _allowed;
    mapping(address => bool) _operators;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrOperators {
        require(msg.sender == owner || _operators[msg.sender]);
        _;
    }

    function allowModule(address module) public onlyOwner {
        _allowed[module] = true;
    }

    function disallowModule(address module) public onlyOwner {
        _allowed[module] = false;
    }

    function addOperator(address operator) public onlyOwner {
        _operators[owner] = true;
    }

    function removeOperator(address operator) public onlyOwner {
        _operators[owner] = false;
    }

    function execModule(address module, bytes memory data) public onlyOwnerOrOperators {
        require(_allowed[module], "execModule/not-allowed");
        (bool ok, bytes memory res) = module.delegatecall(data);
        require(ok, string(res));
    }
}