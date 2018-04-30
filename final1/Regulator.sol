pragma solidity ^0.4.21;

import "./interfaces/RegulatorI.sol";
import "./Owned.sol";
import "./TollBoothOperator.sol";


contract Regulator is RegulatorI, Owned {

    mapping(address => uint) private vehicles;
    mapping(address => bool) private operators;

    function Regulator() public
    {

    }

    function setVehicleType(address vehicle, uint vehicleType)
        public
        fromOwner
        returns(bool success)
    {
        require(vehicle != 0);
        require(vehicles[vehicle] != vehicleType);

        vehicles[vehicle] = vehicleType;
        emit LogVehicleTypeSet(msg.sender, vehicle, vehicleType);

        return true;
    }

    function getVehicleType(address vehicle)
        constant
        public
        returns(uint vehicleType)
    {
        return vehicles[vehicle];
    }

    function createNewOperator(address _owner, uint _deposit)
        public
        fromOwner
        returns(TollBoothOperatorI newOperator)
    {
        require(_owner != owner);
        TollBoothOperator operator = new TollBoothOperator(true, _deposit, _owner);
        operators[address(operator)] = true;
        emit LogTollBoothOperatorCreated(msg.sender, operator, _owner, _deposit);
        return operator;
    }


    function removeOperator(address operator)
        public
        fromOwner
        returns(bool success)
    {
        require(operators[operator]);
        operators[operator] = false;
        emit LogTollBoothOperatorRemoved(msg.sender, operator);
        return true;
    }

    function isOperator(address operator)
        constant
        public
        returns(bool indeed)
    {
        return operators[operator];
    }

}