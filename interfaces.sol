/**
    This is a minimalistic interface of the one of multiple possible implementations.
    In this version every vehicle registers when it enters the road and pays for the trip on the exit booth with a transcation.
 */

/**
    Regulator registers all Operators, so everyone can check if they are paying to actual Operator.
    Regulator can also punish Operator for some violations by withdrawing some funds from their PenaltyDeposits.
    Regulator can also ban Operator if violations continue.
 */
contract Regulator is Owned
{
    function addOperator(address operator) onlyOwner public;
    function removeOperator(address operator) onlyOwner public;   
    
    function imposePenalty(address operator, uint amount) onlyOwner;
    
    function pauseOperator(address operator) onlyOwner;
    function unpauseOperator(address operator) onlyOwner;
}

/**
    Every operator is a regulated entity.
 */
contract Regulated
{
    address public regulator;    
    
    modifier onlyRegulator();
    
    function pauseByRegulator() onlyRegulator;
    function resumeByRegulator() onlyRegulator;

    function changeRegulator(address regulator) onlyRegulator;
}

/**
    Every operator should have some penalty deposit 
    so Regulator can punish Operator for any violation.
 */
contract PenaltyDeposit is Regulated, Owned
{
    function allowWithdraw() onlyRegulator;

    //Only after regulator allows it. It happens when operator is shutting down.
    function withdraw() onlyOwner;
    //Operator can add money to this deposit on regulators request.
    function () onlyOwner payable;

    function imposePenalty(uint amount) onlyRegulator;
}

contract Operator is Regulated, Owned
{
    //On every payment operator will store previous location oh the vehicle.
    function setEntryLocation(address vehicle, address booth);
    function getEntryLocation(address vehicle) returns(address booth);

    function addBooth(address booth) onlyOwner;
    function removeBooth(address booth) onlyOwner;    

    function setPrice(address boothFrom, address boothTo, uint price) onlyOwner;    
}

/**
    Every TollBooth has an operator, that owns this booth.
    Every vehicle can enter or exit the toll road only through the TollBooth.
 */   
contract TollBooth is Owned
{
    modifier operatorActive();

    function entry();
    function getPrice() view returns(uint value);
    //Payment will be successfull only if operator is active and regulated by valid regulator
    function exitAndPay() operatorActive payable;

    function withdrawFunds() operatorActive onlyOwner;
}

/**
    Every operator has a table with prices for the path between every two boothes, 
    that can be entry and exit of the road.
 */
contract PricesManager is Owned
{
    function getPrice(address entryBooth, address exitBooth, uint value) view public;
    ///Only for owner of boothes can edit the price
    function setPrice(address entryBooth, address exitBooth) onlyOwner returns(uint value);
}