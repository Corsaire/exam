
/* Regulator registers all Operators, so everyone can check if they are paying to actual Operator.
 * Regulator can also punish Operator for some violations by withdrawing some funds from their PenaltyDeposits.
 * Regulator can also ban Operator if violations continue.
 */
contract Regulator is Owned
{
    function addOperator(address operator) onlyOwner public;
    function removeOperator(address operator) onlyOwner public;   
    
    function imposePenalty(address operator, uint amount) onlyOwner;
    
    function pauseOperator(address operator) onlyOwner;
    function unpauseOperator(address operator) onlyOwner;
}

/* Every operator should have some penalty deposit 
 * so Regulator can punish Operator for any violation.
 */
contract PenaltyDeposit is Regulated, Owned
{
    function allowWithdraw() onlyRegulator;
    //Only after regulator allows it. It happens when operator is shutting down.
    function withdraw() onlyOwner;
    function replenish() onlyOwner payable;
  
    function imposePenalty(uint amount) onlyRegulator;
}

contract Regulated is Owned
{
    address regulator;
    uint penaltyDeposit;

    modifier onlyRegulator();

    function pause() onlyRegulator;
    function resume() onlyRegulator;
}

contract Operator is Regulated, Owned
{
    function addBooth(address booth);
    function removeBooth(address booth);
}

//This contract read the address information from all vehicles that passes through this toll booth
contract TollBooth is Owned
{

    function pay(address payer, address boothFrom) public payable;
}

contract PricesManager
{
    function getPrice(address boothFrom, address boothTo);
    ///Only for owner of boothes can edit the price
    function setPrice(address boothFrom, address boothTo);
}

/*  This contract will hold all driver/vehicles deposits
*   Money will be withdrawed automatically once driver/vehicle will cross 
*/
contract MoneyManager is Owned
{
    function deposit(address sender) public payable;
    function pay(address from, uint value) public onlyTollBooth returns(bool success);
}