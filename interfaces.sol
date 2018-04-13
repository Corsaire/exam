contract Owned
{
    address owner;
    modifier onlyOwner();
}

contract Regulator is Owned
{
    mapping(address => bool) isOperator;
    Operator[] operators;

    function addOperator(address operator) onlyOwner public;
    function removeOperator(address operator) onlyOwner public;    
}

contract Regulated is Owned
{
    address regulator;
    modifier onlyRegulator();
}

contract Operator is Regulated, Owned
{
    
}

//This contract read the address information from all vehicles that passes through this toll booth
contract TollBooth is Owned
{

}

//This contract will hold all driver/vehicles deposits
contract MoneyManager is Owned
{

}