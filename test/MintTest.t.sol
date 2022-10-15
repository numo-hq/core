pragma solidity ^0.8.4;

import "forge-std/console2.sol";

import { TestHelper } from "./utils/TestHelper.sol";

import { Position } from "../src/libraries/Position.sol";
import { Tick } from "../src/libraries/Tick.sol";

import { Factory } from "../src/Factory.sol";
import { Lendgine } from "../src/Lendgine.sol";
import { CallbackHelper } from "./utils/CallbackHelper.sol";

contract MintTest is TestHelper {
    bytes32 public positionID;

    function setUp() public {
        _setUp();

        _deposit(1 ether, 8 ether, 1 ether, 1, cuh);

        positionID = Position.getID(cuh, 1);
    }

    function testMint() public {
        _mint(5 ether, cuh);
        // console2.log(pair.calcInvariant(10 ether, 0 ether));

        // Test lendgine token
        assertEq(lendgine.totalSupply(), 0.5 ether);
        assertEq(lendgine.balanceOf(cuh), 0.5 ether);
        assertEq(lendgine.balanceOf(address(lendgine)), 0 ether);

        // Test pair token
        assertEq(pair.buffer(), 0.5 ether);
        assertEq(pair.totalSupply(), 1 ether);

        assertPosition(Position.Info({ liquidity: 1 ether, rewardPerLiquidityPaid: 0, tokensOwed: 0 }), positionID);

        assertTick(
            Tick.Info({ liquidity: 1 ether, rewardPerINPaid: 0, tokensOwedPerLiquidity: 0, prev: 0, next: 0 }),
            1
        );

        // Test global storage values
        assertEq(lendgine.currentTick(), 1);
        assertEq(lendgine.currentLiquidity(), 0.5 ether);
        assertEq(lendgine.rewardPerINStored(), 0);
        assertEq(lendgine.lastUpdate(), 1);
        assertEq(lendgine.interestNumerator(), 0.5 ether);
    }

    // function testInsufficientInput() public {
    //     speculative.mint(cuh, 1 ether);

    //     vm.prank(cuh);
    //     speculative.approve(address(this), 1 ether);

    //     vm.expectRevert(Lendgine.InsufficientInputError.selector);

    //     lendgine.mint(
    //         address(this),
    //         2 ether,
    //         abi.encode(MintCallbackHelper.MintCallbackData({ key: key, payer: address(this) }))
    //     );
    // }

    function testZeroMint() public {
        vm.expectRevert(Lendgine.InsufficientOutputError.selector);
        lendgine.mint(
            cuh,
            0 ether,
            abi.encode(CallbackHelper.CallbackData({ speculative: address(speculative), payer: cuh }))
        );
    }

    // function testExtraMint() public {
    //     speculative.mint(cuh, 21 ether);

    //     vm.prank(cuh);
    //     speculative.approve(address(this), 21 ether);

    //     vm.expectRevert(Lendgine.CompleteUtilizationError.selector);
    //     lendgine.mint(cuh, 21 ether, abi.encode(CallbackHelper.CallbackData({ key: key, payer: cuh })));
    // }

    // function testEmptyMint() public {
    //     _withdraw(2 ether - 1000, cuh);

    //     speculative.mint(cuh, 1 ether);

    //     vm.prank(cuh);
    //     speculative.approve(address(this), 1 ether);

    //     vm.expectRevert(Lendgine.CompleteUtilizationError.selector);
    //     lendgine.mint(cuh, 1 ether, abi.encode(CallbackHelper.CallbackData({ key: key, payer: cuh })));
    // }

    function testMintFull() public {
        _mint(10 ether, cuh);
        // console2.log(pair.calcInvariant(10 ether, 0 ether));

        // Test lendgine token
        assertEq(lendgine.totalSupply(), 1 ether);
        assertEq(lendgine.balanceOf(cuh), 1 ether);
        assertEq(lendgine.balanceOf(address(lendgine)), 0 ether);

        // Test pair token
        assertEq(pair.buffer(), 1 ether);
        assertEq(pair.totalSupply(), 1 ether);

        assertPosition(Position.Info({ liquidity: 1 ether, rewardPerLiquidityPaid: 0, tokensOwed: 0 }), positionID);

        assertTick(
            Tick.Info({ liquidity: 1 ether, rewardPerINPaid: 0, tokensOwedPerLiquidity: 0, prev: 0, next: 0 }),
            1
        );

        // Test global storage values
        assertEq(lendgine.currentTick(), 1);
        assertEq(lendgine.currentLiquidity(), 1 ether);
        assertEq(lendgine.rewardPerINStored(), 0);
        assertEq(lendgine.lastUpdate(), 1);
        assertEq(lendgine.interestNumerator(), 1 ether);
    }
}
