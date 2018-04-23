library List
{

}

contract Owned
{
    address owner;
    modifier onlyOwner();
}

contract Regulator is Owned
{
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
    function addBooth(address booth);
    function removeBooth(address booth);
}

//This contract read the address information from all vehicles that passes through this toll booth
contract TollBooth is Owned
{
    Operator operator;

    function pay(address payer) public payable;
}

/*  This contract will hold all driver/vehicles deposits
*   Money will be withdrawed automatically once driver/vehicle will cross 
*/
contract MoneyManager is Owned
{
    function deposit(address sender) public payable;
    function pay(address from, uint value, Operator to) public onlyTollBooth returns(bool success);
}