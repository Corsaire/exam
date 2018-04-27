pragma solidity ^0.4.21;

import "./interfaces/MultiplierHolderI.sol";
import "./Owned.sol";

contract MultiplierHolder is Owned, MultiplierHolderI {

    mapping (uint => uint) internal multipliers;

    function MultiplierHolder() public
    {
    }

    function setMultiplier(uint vehicleType, uint multiplier)
        public
        fromOwner
        returns(bool success)
    {
        require(vehicleType != 0);
        require(multiplier != multipliers[vehicleType]);

        multipliers[vehicleType] = multiplier;
        emit LogMultiplierSet(msg.sender, vehicleType, multiplier);
        return true;
    }

    function getMultiplier(uint vehicleType)
        constant
        public
        returns(uint multiplier)
    {
        return multipliers[vehicleType];
    }

}