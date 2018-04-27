pragma solidity ^0.4.21;

import "./interfaces/RoutePriceHolderI.sol";
import "./TollBoothHolder.sol";

contract RoutePriceHolder is RoutePriceHolderI, TollBoothHolder {

    mapping(address => mapping(address => uint)) private prices;

    function RoutePriceHolder()
    public
    {

    }

    /**
     * Called by the owner of the RoutePriceHolder.
     *     It can be used to update the price of a route, including to zero.
     *     It should roll back if the caller is not the owner of the contract.
     *     It should roll back if one of the booths is not a registered booth.
     *     It should roll back if entry and exit booths are the same.
     *     It should roll back if either booth is a 0x address.
     *     It should roll back if there is no change in price.
     * @param entryBooth The address of the entry booth of the route set.
     * @param exitBooth The address of the exit booth of the route set.
     * @param priceWeis The price in weis of the new route.
     * @return Whether the action was successful.
     * Emits LogPriceSet with:
     *     The sender of the action.
     *     The address of the entry booth.
     *     The address of the exit booth.
     *     The new price of the route.
     */
    function setRoutePrice(address entryBooth, address exitBooth, uint priceWeis)
        public
        fromOwner
        returns(bool success)
    {
        require(entryBooth != 0);
        require(exitBooth != 0);
        require(entryBooth != exitBooth);
        require(isTollBooth(entryBooth));
        require(isTollBooth(exitBooth));
        require(prices[entryBooth][exitBooth] != priceWeis);

        prices[entryBooth][exitBooth] = priceWeis;
        emit LogRoutePriceSet(msg.sender, entryBooth, exitBooth, priceWeis);

        return true;
    }

    function getRoutePrice(address entryBooth, address exitBooth)
        constant
        public
        returns(uint priceWeis)
    {
        return prices[entryBooth][exitBooth];
    }

}