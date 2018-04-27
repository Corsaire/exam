pragma solidity ^0.4.21;

import "./interfaces/RegulatedI.sol";
import "./interfaces/RegulatorI.sol";

contract Regulated is RegulatedI {

    address internal regulator;

    modifier onlyRegulator()
    {
        require(msg.sender == regulator);
        _;
    }

    function Regulated(address _regulator) public
    {
        require(_regulator != 0);
        regulator = _regulator;
    }        

    function setRegulator(address newRegulator)
        public
        onlyRegulator
        returns(bool success)
    {
        require(newRegulator != 0);
        require(newRegulator != regulator);

        emit LogRegulatorSet(regulator, newRegulator);
        regulator = newRegulator;

        return true;
    }

    function getRegulator()
        constant
        public
        returns(RegulatorI _regulator)
    {
        return RegulatorI(regulator);
    }
}