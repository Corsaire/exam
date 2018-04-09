# Exercise 3

## Critical errors

1.  #### ___Re-enterance attack is possible___
    **Description** : Since contract is sending `1/3` of `balance` instead of `msg.value`, it's possible to make re-entrance attack. If `one` is a contract, it can make transaction on Splitters address in its fallback function and drain all ballance of splitter.

    **Solution** : 
    * change `balance` to `msg.value`.  
    * change `call.value` to `.transfer` function. Ot sends little of gas and makes re-entrance impossible. 

    
1. #### ___Solidity version___ 
    **Description** :`revert` is not supported in 0.4.9.

    **Solution** : use latest solidity version 0.4.21.

    
1. #### ___Contract balance___ 
    **Description** : no way to receive Ether from contract.

    **Solution** : we need to add posibility to spend Ether from contract: 
    * add all `owner` functionality
    * add `withdraw` function that transfers all balance to `owner`

    
1. #### ___Making 2 money transfers___ 
    **Description** :`revert` is not supported in 0.4.9.

    **Solution** : use latest solidity version 0.4.21.



## Other suggestions


1. #### ___solidity version___ 
    **Description** :`require` is not supported in 0.4.9.

    **Solution** : use latest solidity version 0.4.21.
    
