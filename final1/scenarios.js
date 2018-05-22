const expectedExceptionPromise = require('../utils/expectedException.js')
web3.eth.getTransactionReceiptMined = require('../utils/getTransactionReceiptMined.js')
const Promise = require('bluebird')
Promise.allNamed = require('../utils/sequentialPromiseNamed.js')
const randomIntIn = require('../utils/randomIntIn.js')
const toBytes32 = require('../utils/toBytes32.js')

if (typeof web3.eth.getAccountsPromise === 'undefined') {
    Promise.promisifyAll(web3.eth, { suffix: 'Promise' })
}

const Regulator = artifacts.require('./Regulator.sol')
const TollBoothOperator = artifacts.require('./TollBoothOperator.sol')

contract('Scenarios', function (accounts) {
    let owner0, owner1,
        booth0, booth1, booth2,
        vehicle0, vehicle1,
        regulator, operator,
        startBalance0, startBalance1,
        thirdParty;
    const price01 = randomIntIn(1, 1000) * 100
    //const deposit0 = price01 + randomIntIn(1, 1000) * 100
    const deposit0 = 10000;
    const deposit1 = deposit0 + randomIntIn(1, 1000) * 100
    const vehicleType0 = randomIntIn(1, 1000) * 100
    const vehicleType1 = vehicleType0 + randomIntIn(1, 1000) * 100
    //const multiplier0 = randomIntIn(1, 1000) * 100
    const multiplier0 = 5
    const multiplier1 = 6;//multiplier0 + randomIntIn(1, 1000) * 100
    const tmpSecret = randomIntIn(1, 1000)
    const secret0 = toBytes32(tmpSecret)
    const secret1 = toBytes32(tmpSecret + randomIntIn(1, 1000))
    let hashed0, hashed1

    before('should prepare', function () {
        assert.isAtLeast(accounts.length, 8)
        owner0 = accounts[0]
        owner1 = accounts[1]
        booth0 = accounts[2]
        booth1 = accounts[3]
        booth2 = accounts[4]
        vehicle0 = accounts[5]
        vehicle1 = accounts[6]
        thirdParty = accounts[7]
        return web3.eth.getBalancePromise(owner0)
            .then(balance => assert.isAtLeast(web3.fromWei(balance).toNumber(), 1))
    });

    describe('Preparing for scenarios', function () {

        function enterTheRoad(vehicle, booth, hashed, deposit) {
            return operator.enterRoad(booth, hashed, { from: vehicle, gas: 3000000, value: deposit })
                .then(() => web3.eth.getBalancePromise(vehicle));
        }

        function checkPending(tx, logIndex, hashed, boothEnter, boothExit)
        {
            const logEntered = tx.logs[logIndex];
            assert.strictEqual(logEntered.event, 'LogPendingPayment');
            assert.strictEqual(logEntered.args.exitSecretHashed, hashed);
            assert.strictEqual(logEntered.args.entryBooth, boothEnter);
            assert.strictEqual(logEntered.args.exitBooth, boothExit);
        }
        
        function checkExit(tx, logIndex, finalFee, refundWeis, boothExit)
        {
            const logEntered = tx.logs[logIndex];
            assert.strictEqual(logEntered.event, 'LogRoadExited');
            assert.strictEqual(logEntered.args.exitBooth, boothExit);
            assert.strictEqual(logEntered.args.finalFee.toNumber(), Math.round(finalFee));
            assert.strictEqual(logEntered.args.refundWeis.toNumber(), Math.round(refundWeis));                
        }

        beforeEach('should deploy regulator and operator', function () {
            return Regulator.new({ from: owner0 })
                .then(instance => regulator = instance)
                .then(() => regulator.setVehicleType(vehicle0, vehicleType0, { from: owner0 }))
                .then(() => regulator.setVehicleType(vehicle1, vehicleType1, { from: owner0 }))
                .then(tx => regulator.createNewOperator(owner1, deposit0, { from: owner0 }))
                .then(tx => operator = TollBoothOperator.at(tx.logs[1].args.newOperator))
                .then(() => operator.addTollBooth(booth0, { from: owner1 }))
                .then(tx => operator.addTollBooth(booth1, { from: owner1 }))
                .then(tx => operator.setMultiplier(vehicleType0, multiplier0, { from: owner1 }))
                .then(tx => operator.setMultiplier(vehicleType1, multiplier1, { from: owner1 }))
                .then(tx => operator.setRoutePrice(booth0, booth1, price01, { from: owner1 }))
                .then(tx => operator.setPaused(false, { from: owner1 }))
                .then(tx => operator.hashSecret(secret0))
                .then(hash => hashed0 = hash)
                .then(tx => operator.hashSecret(secret1))
                .then(hash => hashed1 = hash);
        });

        it('Scenario 1: should pay deposit, equals price route, exit, no refund', function () {
            return operator.setRoutePrice(booth0, booth1, deposit0, { from: owner1 })
            .then(tx => enterTheRoad(vehicle0, booth0, hashed0, multiplier0 * deposit0))
            .then(balance => {startBalance0 = balance})
            .then(() => operator.reportExitRoad.call(secret0, { from: booth1, gas: 3000000 }))
            .then(res => assert.equal(res, 1))
            .then(() => operator.reportExitRoad(secret0, { from: booth1, gas: 3000000 }))
            .then(tx => web3.eth.getBalancePromise(vehicle0))
            .then(balance => assert.equal(balance.toString(), startBalance0.toString()))
        });

        it('Scenario 2: should pay deposit, less than price route, exit, no refund', function () {
            return operator.setRoutePrice(booth0, booth1, deposit0 * 1.5, { from: owner1 })
            .then(tx => enterTheRoad(vehicle0, booth0, hashed0, multiplier0 * deposit0))
            .then(balance => {startBalance0 = balance})
            .then(() => operator.reportExitRoad.call(secret0, { from: booth1, gas: 3000000 }))
            .then(res => assert.equal(res, 1))
            .then(() => operator.reportExitRoad(secret0, { from: booth1, gas: 3000000 }))
            .then(tx => web3.eth.getBalancePromise(vehicle0))
            .then(balance => assert.equal(balance.toString(), startBalance0.toString()))
        });
        
        it('Scenario 3: should pay deposit, more than price route, exit, get refund', function () {
            return operator.setRoutePrice(booth0, booth1, deposit0 * 0.6, { from: owner1 })
            .then(tx => enterTheRoad(vehicle0, booth0, hashed0, multiplier0 * deposit0))
            .then(balance => {startBalance0 = balance})
            .then(() => operator.reportExitRoad.call(secret0, { from: booth1, gas: 3000000 }))
            .then(res => assert.equal(res, 1))
            .then(() => operator.reportExitRoad(secret0, { from: booth1, gas: 3000000 }))
            .then(tx => web3.eth.getBalancePromise(vehicle0))
            .then(balance => 
                {
                      assert.equal(balance.toString(), (startBalance0.add( multiplier0 * deposit0 * 0.4 )).toString())
                }
                );
        });
        
        it('Scenario 4: should pay more than deposit, price route equals deposit, exit, refund', function () {
            return operator.setRoutePrice(booth0, booth1, deposit0, { from: owner1 })
            .then(tx => enterTheRoad(vehicle0, booth0, hashed0, multiplier0 * deposit0 * 1.4))
            .then(balance => {startBalance0 = balance})
            .then(() => operator.reportExitRoad.call(secret0, { from: booth1, gas: 3000000 }))
            .then(res => assert.equal(res, 1))
            .then(() => operator.reportExitRoad(secret0, { from: booth1, gas: 3000000 }))
            .then(tx =>
                {    
                    assert.strictEqual(tx.logs.length, 1);
                    checkExit(tx, 0, multiplier0 * deposit0, multiplier0 * deposit0 * 0.4, booth1);
                })
            .then(tx => web3.eth.getBalancePromise(vehicle0))
            .then(balance => assert.equal(balance.toString(), (startBalance0.add( multiplier0 * deposit0 * 0.4 )).toString()));
        });
        
        it('Scenario 5: price unknown, should pay more than deposit, exit with pending payment, price route more than deposit and less than deposited, refund', function () {
            return operator.setRoutePrice(booth0, booth1, 0, { from: owner1 })
            .then(tx => enterTheRoad(vehicle0, booth0, hashed0, multiplier0 * deposit0 * 1.4))
            .then(balance => {startBalance0 = balance})
            .then(() => operator.reportExitRoad(secret0, { from: booth1, gas: 3000000 }))
            .then(tx =>
                {    
                    assert.strictEqual(tx.logs.length, 1);
                    checkPending(tx, 0, hashed0, booth0, booth1);
                })
            .then(() => operator.setRoutePrice(booth0, booth1, deposit0 * 1.1, { from: owner1 }))
            .then(tx =>
                {    
                    assert.strictEqual(tx.logs.length, 2);
                    checkExit(tx, 1, multiplier0 * deposit0 * 1.1, multiplier0 * deposit0 * 0.3, booth1);
                })
            .then(tx => web3.eth.getBalancePromise(vehicle0))
            .then(balance => assert.equal(balance.toString(), (startBalance0.add( multiplier0 * deposit0 * 0.3 )).toString()));
        });
        
        it('Scenario 6: price unknown, 2 cars, should pay more and equal deposit, both exit, price is set to less than deposit(first gets refund), \n anyone calls clearPendingPayments, 2 gets refund  refund', function () {
            let price = deposit0 * 0.6;
            return operator.setRoutePrice(booth0, booth1, 0, { from: owner1 })
            .then(tx => enterTheRoad(vehicle0, booth0, hashed0, multiplier0 * deposit0 * 1.4))
            .then(balance => {startBalance0 = balance})
            .then(tx => enterTheRoad(vehicle1, booth0, hashed1, multiplier1 * deposit0 ))
            .then(balance => {startBalance1 = balance})
            .then(() => operator.reportExitRoad(secret0, { from: booth1, gas: 3000000 }))
            .then(tx =>
                {    
                    assert.strictEqual(tx.logs.length, 1);
                    checkPending(tx, 0, hashed0, booth0, booth1);
                })
            .then(() => operator.reportExitRoad(secret1, { from: booth1, gas: 3000000 }))
            .then(tx =>
                {    
                    assert.strictEqual(tx.logs.length, 1);
                    checkPending(tx, 0, hashed1, booth0, booth1);
                })
            .then(() => operator.setRoutePrice(booth0, booth1, deposit0 * 0.6, { from: owner1 }))
            .then(tx =>
                {
                    assert.strictEqual(tx.logs.length, 2);
                    checkExit(tx, 1, multiplier0 * deposit0 * 0.6, multiplier0 * deposit0 * 0.8, booth1);
                })
            .then(tx => web3.eth.getBalancePromise(vehicle0))
            .then(balance => assert.equal(balance.toString(), (startBalance0.add( multiplier0 * deposit0 * 0.8 )).toString()))
            .then(() => operator.clearSomePendingPayments(booth0, booth1, 1, { from: thirdParty, gas: 3000000 }))
            .then(tx => 
            {
                assert.strictEqual(tx.logs.length, 1);
                checkExit(tx, 0, multiplier1 * deposit0 * 0.6, multiplier1 * deposit0 * 0.4, booth1);
            })
            .then(tx => web3.eth.getBalancePromise(vehicle1))
            .then(balance => assert.equal(balance.toString(), (startBalance1.add( multiplier1 * deposit0 * 0.4 )).toString()))
            
        });
    });
});