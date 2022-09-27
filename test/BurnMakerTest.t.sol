pragma solidity ^0.8.4;

import "forge-std/console2.sol";

import { TestHelper } from "./utils/TestHelper.sol";
import { CallbackHelper } from "./utils/CallbackHelper.sol";

import { LendgineAddress } from "../src/libraries/LendgineAddress.sol";
import { Position } from "../src/libraries/Position.sol";

import { Factory } from "../src/Factory.sol";
import { Lendgine } from "../src/Lendgine.sol";

contract BurnMakerTest is TestHelper {
    bytes32 public positionID;

    function setUp() public {
        _setUp();

        _mintMaker(1 ether, 1 ether, 1, cuh);

        positionID = Position.getId(cuh, 1);
    }

    function testBurnMakerPartial() public {
        _burnMaker(1 ether - 500, 1, cuh);

        assertEq(pair.balanceOf(cuh), 1 ether - 500);
        assertEq(pair.balanceOf(address(lendgine)), 1 ether - 500);
        assertEq(pair.totalSupply(), 2 ether);

        (uint256 liquidity, uint256 tokensOwed, uint256 rewardPerTokenPaid) = lendgine.positions(positionID);

        assertEq(liquidity, 1 ether - 500);
        assertEq(tokensOwed, 0);
        assertEq(rewardPerTokenPaid, 0);

        (liquidity, tokensOwed, rewardPerTokenPaid) = lendgine.ticks(1);

        assertEq(liquidity, 1 ether - 500);
        assertEq(tokensOwed, 0);
        assertEq(rewardPerTokenPaid, 0);

        assertEq(lendgine.currentTick(), 1);
        assertEq(lendgine.currentLiquidity(), 0);
        assertEq(lendgine.rewardPerTokenStored(), 0);
        assertEq(lendgine.lastUpdate(), 0);
    }

    function testBurnMakerFull() public {
        _burnMaker(2 ether - 1000, 1, cuh);

        assertEq(pair.balanceOf(cuh), 2 ether - 1000);
        assertEq(pair.balanceOf(address(lendgine)), 0 ether);
        assertEq(pair.totalSupply(), 2 ether);

        (uint256 liquidity, uint256 tokensOwed, uint256 rewardPerTokenPaid) = lendgine.positions(positionID);

        assertEq(liquidity, 0 ether);
        assertEq(tokensOwed, 0);
        assertEq(rewardPerTokenPaid, 0);

        (liquidity, tokensOwed, rewardPerTokenPaid) = lendgine.ticks(1);

        assertEq(liquidity, 0 ether);
        assertEq(tokensOwed, 0);
        assertEq(rewardPerTokenPaid, 0);

        assertEq(lendgine.currentTick(), 1);
        assertEq(lendgine.currentLiquidity(), 0);
        assertEq(lendgine.rewardPerTokenStored(), 0);
        assertEq(lendgine.lastUpdate(), 0);
    }

    function testZeroBurn() public {
        vm.expectRevert(Lendgine.InsufficientOutputError.selector);
        lendgine.burnMaker(1, 0 ether);
    }

    // function testOverBurn() public {
    //     vm.expectRevert(Lendgine.InsufficientPositionError.selector);
    //     _burnMaker(2 ether, cuh);
    // }
}
