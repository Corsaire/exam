pragma solidity ^0.4.21;

import "./interfaces/DepositHolderI.sol";
import "./Owned.sol";

contract DepositHolder is Owned, DepositHolderI {

    uint private deposit;

    function DepositHolder(uint _deposit) 
    public    
    {
        require(deposit != 0);
        deposit = _deposit;
    }

    /**
     * Called by the owner of the DepositHolder.
     *     It should roll back if the caller is not the owner of the contract.
     *     It should roll back if the argument passed is 0.
     *     It should roll back if the argument is no different from the current deposit.
     * @param depositWeis The value of the deposit being set, measured in weis.
     * @return Whether the action was successful.
     * Emits LogDepositSet with:
     *     The sender of the action.
     *     The new value that was set.
     */
    function setDeposit(uint depositWeis)
        public
        fromOwner
        returns(bool success)
    {
        require(depositWeis != deposit);
        require(depositWeis != 0);
        deposit = depositWeis;
        emit LogDepositSet(msg.sender, deposit);
        return true;
    }

    function getDeposit()
        constant
        public
        returns(uint weis)
    {
        return deposit;
    }

}