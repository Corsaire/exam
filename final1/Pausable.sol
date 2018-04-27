pragma solidity ^0.4.21;

import "./interfaces/PausableI.sol";
import "./Owned.sol";

contract Pausable is Owned, PausableI {

    bool private paused;
    
    event LogPausedSet(address indexed sender, bool indexed newPausedState);

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier whenNotPaused() {        
        require(!paused);
        _;
    }

    function Pausable(bool _paused) public
    {
        paused = _paused;
    }

    function setPaused(bool newState) fromOwner public returns(bool success)
    {
        require(newState!=paused);
        paused = newState;
        emit LogPausedSet(msg.sender, paused);
        return true;
    }

    function isPaused() constant public returns(bool isIndeed)
    {
        return paused;
    }

}