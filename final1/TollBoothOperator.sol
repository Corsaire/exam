pragma solidity ^0.4.21;

import "./interfaces/TollBoothOperatorI.sol";
import "./RoutePriceHolder.sol";
import "./Pausable.sol";
import "./Regulated.sol";
import "./Regulator.sol";
import "./DepositHolder.sol";
import "./MultiplierHolder.sol";

contract TollBoothOperator is TollBoothOperatorI, DepositHolder, RoutePriceHolder, Pausable, Regulated, MultiplierHolder {

    uint collectedFees;

    enum Status { Empty, OnRoad, Pending, Finished }
    struct VehicleOnRoad
    {
        address vehicle;        
        uint deposit;
        address entryBooth;
        Status status;
    }

    struct PendingPayment
    {
        bytes32[] secretHashes;
        uint startIndex;
    }

    mapping(bytes32 => VehicleOnRoad) public vehiclesOnRoad;
    mapping(address => mapping(address => PendingPayment)) pendingPayments;

    modifier onlyVehicle(address vehicle)
    {
        require(Regulator(regulator).getVehicleType(vehicle) != 0);
        _;
    }

    function TollBoothOperator(bool _paused, uint _deposit, address _regulator)
    Pausable(_paused)
    DepositHolder(_deposit)
    Regulated(_regulator)
    public 
    {

    }

    function getMultiplierByVehicle(address vehicle)
    constant
    public
    returns(uint)
    {
        var vType = Regulator(regulator).getVehicleType(vehicle);
        return (getMultiplier(vType));
    }
    /**
     * This provides a single source of truth for the encoding algorithm.
     * It will be called:
     *     - by the vehicle prior to sending a deposit.
     *     - by the contract itself when submitted a clear password by a toll booth.
     * @param secret The secret to be hashed.
     * @return the hashed secret.
     */
    function hashSecret(bytes32 secret)
        constant
        public
        returns(bytes32 hashed)
    {
        require(secret != 0);
        return keccak256(secret);
        //require (Regulator(regulator).getVehicleType(msg.sender) > 0);
    }

    /**
     * Called by the vehicle entering a road system.
     * Off-chain, the entry toll booth will open its gate after a successful deposit and a confirmation
     * of the vehicle identity.
     *     It should roll back when the contract is in the `true` paused state.
     *     It should roll back when the vehicle is not a registered vehicle.
     *     It should roll back when the vehicle is not allowed on this road system.
     *     It should roll back if `entryBooth` is not a tollBooth.
     *     It should roll back if less than deposit * multiplier was sent alongside.
     *     It should roll back if `exitSecretHashed` has previously been used by anyone to enter.
     *     It should be possible for a vehicle to enter "again" before it has exited from the 
     *       previous entry.
     * @param entryBooth The declared entry booth by which the vehicle will enter the system.
     * @param exitSecretHashed A hashed secret that when solved allows the operator to pay itself.
     * @return Whether the action was successful.
     * Emits LogRoadEntered with:
     *     The sender of the action.
     *     The address of the entry booth.
     *     The hashed secret used to deposit.
     *     The amount deposited by the vehicle.
     */
    function enterRoad(address entryBooth, bytes32 exitSecretHashed)
        public
        payable
        whenNotPaused
        returns (bool success)
    {        
        require(isTollBooth(entryBooth));             
        require(vehiclesOnRoad[exitSecretHashed].status == Status.Empty);   
        var mult = getMultiplierByVehicle(msg.sender);
        require(mult != 0);        
        require(msg.value >= getDeposit() * mult);

        var vehicle = VehicleOnRoad(msg.sender, msg.value, entryBooth, Status.Empty);
        vehiclesOnRoad[exitSecretHashed] = vehicle;
        emit LogRoadEntered(msg.sender, entryBooth, exitSecretHashed, msg.value);
        return true;
    }

    /**
     * @param exitSecretHashed The hashed secret used by the vehicle when entering the road.
     * @return The information pertaining to the entry of the vehicle.
     *     vehicle: the address of the vehicle that entered the system.
     *     entryBooth: the address of the booth the vehicle entered at.
     *     depositedWeis: how much the vehicle deposited when entering.
     * After the vehicle has exited, `depositedWeis` should be returned as `0`.
     * If no vehicles had ever entered with this hash, all values should be returned as `0`.
     */
    function getVehicleEntry(bytes32 exitSecretHashed)
        constant
        public
        returns(address vehicle, address entryBooth, uint depositedWeis)
    {
        var v = vehiclesOnRoad[exitSecretHashed];
        return (v.vehicle, v.entryBooth, v.deposit);
    }

    function reportExitRoad(bytes32 exitSecretClear)
        public
        whenNotPaused
        returns (uint status)
    {
        require(isTollBooth(msg.sender));

        var hashed = hashSecret(exitSecretClear);
        VehicleOnRoad storage v = vehiclesOnRoad[hashed];
        require(v.status == Status.OnRoad); 
        var multiplier = getMultiplierByVehicle(v.vehicle);
        require(multiplier != 0);     

        var price = getRoutePrice(v.entryBooth, msg.sender) * multiplier;
        if(price != 0)
        {    
            processPaymentUnsafe(v, hashed, price);        
            return 1;
        }
        else 
        {
            emit LogPendingPayment(hashed, v.entryBooth, msg.sender);
            v.status = Status.Pending;
            return 2;
        }
    }

    function processPaymentUnsafe(VehicleOnRoad storage v, bytes32 hashed, uint price) 
    private 
    returns(bool)
    {
        var deposit = v.deposit;
        uint change = price < deposit ? deposit-price : 0;
        collectedFees += deposit - change;
        emit LogRoadExited(msg.sender, hashed, deposit-change, change);
        v.status = Status.Finished;  
        //Since it's said that all vehicles are externally owned accounts (not a contract) and the
        //Regulator can actually check this before registering vehicle, we can safely use .transfer
        //without fear that some of the transfers will be rejected and other payments will be locked
        if(change > 0)
            v.vehicle.transfer(change);
        return true;
    }

    function getPendingPaymentCount(address entryBooth, address exitBooth)
        constant
        public
        returns (uint count)
    {
        var payments = pendingPayments[entryBooth][exitBooth];
        return payments.secretHashes.length - payments.startIndex;
    }

    function clearSomePendingPayments(address entryBooth, address exitBooth, uint count)
        public
        whenNotPaused
        returns (bool success)
    {                
        require(isTollBooth(entryBooth));
        require(isTollBooth(exitBooth));
        require(count > 0);

        uint basePrice = getRoutePrice(entryBooth, exitBooth);
        require(basePrice > 0);

        var payments = pendingPayments[entryBooth][exitBooth];

        require(count <= payments.secretHashes.length);
        for(uint i = 0; i < count; i++)
        {
            var hashed = payments.secretHashes[payments.startIndex];
            VehicleOnRoad storage v = vehiclesOnRoad[hashed];
            processPaymentUnsafe(v,hashed, getMultiplierByVehicle(v.vehicle) * basePrice);
            payments.startIndex++;
        }
        return true;
    }

    function getCollectedFeesAmount()
        constant
        public
        returns(uint amount)
    {
        return collectedFees;
    }


    function withdrawCollectedFees()
        public
        fromOwner
        returns(bool success)
    {
        require(collectedFees > 0);
        uint amount = collectedFees;
        collectedFees = 0;
        owner.transfer(amount);
        emit LogFeesCollected(owner, amount);
        return true;
    }

    /**
     * This function is commented out otherwise it prevents compilation of the completed contracts.
     * This function overrides the eponymous function of `RoutePriceHolderI`, to which it adds the following
     * functionality:
     *     - If relevant, it will release 1 pending payment for this route. As part of this payment
     *       release, it will emit the appropriate `LogRoadExited` event.
     *     - In the case where the next relevant pending payment, i.e. at the top of the FIFO, is not solvable,
     *       which can happen if, for instance the vehicle has had wrongly set values (such as type or multiplier)
     *       in the interim:
     *       - It should release 0 pending payment
     *       - It should not roll back the transaction
     *       - It should behave as if there had been no pending payment, apart from the higher gas consumed.
     *     - It should be possible to call it even when the contract is in the `true` paused state.
     * Emits LogRoadExited, if applicable, with:
     *       The address of the exit booth.
     *       The hashed secret corresponding to the vehicle trip.
     *       The effective charge paid by the vehicle.
     *       The amount refunded to the vehicle.
     */
    // function setRoutePrice(
    //         address entryBooth,
    //         address exitBooth,
    //         uint priceWeis)
    //     public
    //     returns(bool success);

    /*
     * You need to create:
     *
     * - a contract named `TollBoothOperator` that:
     *     - is `OwnedI`, `PausableI`, `DepositHolderI`, `TollBoothHolderI`,
     *         `MultiplierHolderI`, `RoutePriceHolderI`, `RegulatedI` and `TollBoothOperatorI`.
     *     - has a constructor that takes:
     *         - one `bool` parameter, the initial paused state.
     *         - one `uint` parameter, the initial deposit wei value, which cannot be 0.
     *         - one `address` parameter, the initial regulator, which cannot be 0.
     */
}