# Exercise 3

## Critical errors

1.  #### ___Re-enterance attack is possible___
    **Description** : Since contract is sending `1/3` of `balance` instead of `msg.value`, it's possible to make re-entrance attack. If `one` is a contract, it can make a transaction on the Splitter address in its fallback function and drain all balance of the Splitter.

    **Solution** : 
    * change `balance` to `msg.value`.  
    * change `call.value` to `.transfer` function. It sends little gas and makes re-entrance impossible. 
    * instead of transferring Ether to `one` and `two` in fallback function it's better to make `withdraw` function for everyone to withdraw their Ether.

    
1. #### ___Solidity version___ 
    **Description** :`revert` is not supported in 0.4.9.

    **Solution** : use latest solidity version 0.4.21.

    
1. #### ___Contract balance___ 
    **Description** : no way to receive Ether from the contract. Any Ether kept in the contract is lost forever.

    **Solution** : we need to add the possibility to spend Ether from the contract: 
    * add all `Owned` functionality
    * add `withdrawContractEther` function that transfers all balance to `owner`


## Other suggestions


1. #### ___`one` is always a contract creator___ 
    **Description** : `one` is always a contract creator.

    **Solution** : add `one` as a parameter to constructor.

1. #### ___Validations___ 
    **Description** : Validation of input data is always a good idea. 

    **Solution** :  
    * Add `one` and `two` zero address check.
    * Add `require(msg.value > 0);` check in fallback function.
    * No need to check `if (msg.value > 0) revert();` in constructor. It's not payable.

1. #### ___No events___ 
    **Description** : It's good practice to emit events on every significant storage change.

    **Solution** : add `event` to log every send and withdraw actions.

1. ### ___Visibility___
    **Description** : It's a good practice to explicitly specify visibility. 

    **Solution** : specify visibility for all functions and fields.
