# Exercise 1

## Critical errors

1.  #### ___Constructor starts with the lower case___ 
    **Description** : `piggyBank` is just a function, that can be called anytime. Anyone can become the owner. 

    **Solution** : Rename `piggyBank` to `PiggyBank` in order to make it a constructor.

1. #### ___Constructor is not payable___ 
    **Description** : The constructor is not `payable` but is intended to receive some Ether (because it works with `msg.value`).

    **Solution** : Add `payable` to constructor


1. #### ___No `pragma solidity`___ 
    **Description** : Not every version of solidity can compile that code (`revert` was added in solidity version `0.4.10`). 

    **Solution** : add `pragma solidity ^0.4.21;`

1. #### ___Function `kill` can be called by anyone___ 
    **Description** : `kill` should only be called by owner due to the project description. Also, when owner sends `password`, anyone on the network can see the password. No major attack can be built there because contract only sends its Ether to the owner (if we fix constructor, of course). But there is a possible scenario when owner sends a transaction to call `kill` function and then changes his mind and sends another transaction with the same nonce without calling `kill`. Any attacker will be able to kill contract after that.  

    **Solution** : Add `if (msg.sender != owner) revert();` to `kill` function

## Other suggestions

1. #### ___`uint248 balance`___ 
    **Description** : `uint248` requires explicit conversion from `msg.value` and using `uint248` will cost even more gas.  

    **Solution** : Change `uint248` to `uint`

1. #### ___`balance is not public`___ 
    **Description** : `balance` field is not actually used anywhere. No one can view the amount of Ether that owner sent to contract.  

    **Solution** : Change `balance` visibility to `public`, if we want anyone (and owner) to be able to look at the amount of Ether, that owner sent to the contract. Contract balance can be different, though (if any other contract self-destructed or mined a new block in favor of our contract).

1. #### ___Selfdestruct vs "Stoppable functionality + owner.transfer(balance);"___ 
    **Description** : There are two ways of creating this contract functionality:
    * We need to use `owner.transfer(balance);` if we want to receive exactly the same amount of Ether, that was sent to the contract by the `owner`. Other Ether will be lost forever.
    * If we want to collect all the Ether from the contract we can use either `owner.transfer(address(this).balance);` or proceed with `selfdestruct`.
    
    Anyway, if we do not want to destroy our contract we need to add ___Stoppable___ functionality (ability for the owner to stop any contract activity).\
    Destroying contract is rarely a good idea, but in this case, with a simple contract like that, it could be useful to clean up Ethereum state from this contract. It will also be much cheaper than `transfer`. \
     ***But we must always be very careful with `selfdestruct`*** .

1. #### ___Validations___ 
    **Description** : Validation of input data is always a good idea. 

    **Solution** :  
    * Add `msg.value > 0` validation in fallback function.
    * Add `_hashedPassword != 0` validation in constructor.

1. #### ___No events___ 
    **Description** : It's a good practice to emit events on every significant storage changes.

    **Solution** :  Add `event` for creation, every payment, and destruction of a contract.

1. ### ___Visibility___
    **Description** : It's a good practice to explicitly specify visibility. 

    **Solution** : Specify visibility for all functions and fields.


1. ### ___Code structure___
    **Description** : It could be a good idea to transfer ownership functionality to parent contract `Owned`. We can also create functionality for changing `owner` and creating `onlyOwner` modifier. 
