pragma solidity ^0.4.21;


import "./interfaces/TollBoothHolderI.sol";
import "./Owned.sol";

contract TollBoothHolder is TollBoothHolderI, Owned {

    mapping(address => bool) private tollBoothes;

    function TollBoothHolder()
    public
    {

    }

    function addTollBooth(address tollBooth)
        public
        fromOwner
        returns(bool success)
    {
        require(tollBooth != 0);
        require(!tollBoothes[tollBooth]);

        tollBoothes[tollBooth] = true;
        emit LogTollBoothAdded(msg.sender, tollBooth);
        return true;
    }

    function isTollBooth(address tollBooth)
        constant
        public
        returns(bool isIndeed)
    {
        return tollBoothes[tollBooth];
    }

    function removeTollBooth(address tollBooth)
        public
        fromOwner
        returns(bool success)
    {
        require(tollBooth != 0);
        require(tollBoothes[tollBooth]);

        tollBoothes[tollBooth] = true;
        emit LogTollBoothRemoved(msg.sender, tollBooth);
        return true;
    }

}