# Exercise 2

## Critical errors

1.  #### ___`purchase` is not `payable`___ 
    **Description** : `purchase` is not `payable` but works with `msg.value`. 

    **Solution** : add `payable` to `purchase`

1.  #### ___`send` can return `false`___ 
    **Description** : `send` can return `false` and purchase will still be shipped. 

    **Solution** : It's better to use `transfer` instead, it will call `revert` if Ether won't be transferred. \
     _If would like to still use 0.4.5 version of solidity, we could just switch `wallet.send(msg.value);` with `if(!wallet.send(msg.value)) throw;`. But it's no need to keep the old version of solidity._
    
1.  #### ___`warehouse.ship` can return `false`___ 
    **Description** : `warehouse.ship` can return `false` and Ether will still be transferred. 

    **Solution** : check if shipment was successful: `if (!warehouse.ship(id, msg.sender)) revert();`
    
1.  #### ___Solidity version___ 
    **Description** : Version `0.4.5` does not contain `transfer` and `revert` 
    
    **Solution** : if we want to fix the previous bug efficiently, better to change solidity version to latest 0.4.21.
    
1.  #### ___No delivery address___ 
    **Description** : I assume, Warehouse interface is designed to receive delivery address before every `ship` call. 

    **Solution** : set delivery address before each shipment. It could also be useful to add `string deliveryAddress` parameter to `ship` function in WarehouseI if we are able to change the interface in this exercise.

1. ### ___No checking if `msg.value` is big enough___
    **Description** : Sender can send any value (even zero) and purchase will be shipped.

    **Solution** : Check if `msg.vaue` is big enough. If `id` is product id, then we could have `mapping(uint => uint) prices;` to store prices for each product id. Then we can validate: `require(msg.value >= prices[id]);` 
    Also if we want to store prices in this contract, we would need to add a few things:
        * add `addProduct` and `removeProduct`, `editProductPrice` that only owner can call.
        * add all `Owned` functionality as a parent contract.


## Other suggestions


1. #### ___`warehouse` and `wallet`___ 
    **Description** : `warehouse` and `wallet` fields are immutable and single. It's possible that we would like to change or work with multiple wallets and/or warehouses.

    **Solution** : add functions to edit warehouse and wallet (only for the owner). And possibly keep multiple wallets/warehouses. Adding more warehouses and wallets also require some algorithms to determine which wallet/warehouses to use.

1. #### ___`contract` keyword___ 
    **Description** : `WarehouseI` is assumed to be an interface, but declared with a `contract` keyword. It will also work with `contract` though, but it's a better practice to use `interface` here. Since 0.4.11

    **Solution** :  change `contract` to `interface`

1. #### ___Validations___ 
    **Description** : Validation of input data is always a good idea. 

    **Solution** :  
    * Add `wallet` and `warehouse` validation on creation and editing.
    * Add `uint` validation on creation and editing.

1. #### ___No events___ 
    **Description** : It's good practice to emit events on every significant storage change.

    **Solution** :  add `event` to log every purchase.

1. ### ___Visibility___
    **Description** : It's a good practice to explicitly specify visibility. 

    **Solution** : specify visibility for all functions and fields.
