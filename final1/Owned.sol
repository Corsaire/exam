pragma solidity ^0.4.21;

import "./interfaces/OwnedI.sol";

contract Owned is OwnedI {

    address internal owner;
    event LogOwnerSet(address indexed previousOwner, address indexed newOwner);

    modifier fromOwner() {
        require(owner == msg.sender);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function setOwner(address newOwner) 
    public 
    fromOwner
    returns(bool success)
    {
        require(newOwner!=owner);
        require(newOwner!=0);
        owner = newOwner;
        emit LogOwnerSet(msg.sender, newOwner);
        return true;
    }

    function getOwner() 
    constant 
    public 
    returns(address _owner)
    {
        return owner;
    }
}