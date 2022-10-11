pragma solidity ^0.8.4;

import "forge-std/console2.sol";

import { TestHelper } from "./utils/TestHelper.sol";
import { CallbackHelper } from "./utils/CallbackHelper.sol";

import { LendgineAddress } from "../src/libraries/LendgineAddress.sol";
import { Position } from "../src/libraries/Position.sol";

import { Factory } from "../src/Factory.sol";
import { Lendgine } from "../src/Lendgine.sol";

contract BurnTest is TestHelper {
    bytes32 public positionID;

    function setUp() public {
        _setUp();

        _mintMaker(1 ether, 1 ether, 1 ether, 1, cuh);

        _mint(10 ether, cuh);

        positionID = Position.getId(cuh, 1);
    }

    function testBurnPartial() public {
        _burn(5 * 10**35, cuh);

        // Test lendgine token
        assertEq(lendgine.totalSupply(), 5 * 10**35);
        assertEq(lendgine.balanceOf(cuh), 5 * 10**35);
        assertEq(lendgine.balanceOf(address(lendgine)), 0 ether);

        // // Test base token
        assertEq(pair.buffer(), 5 * 10**35);

        // Test speculative token
        assertEq(speculative.balanceOf(cuh), 5 ether);
        assertEq(speculative.balanceOf(address(lendgine)), 5 ether);

        (uint256 liquidity, uint256 rewardPerLiquidityPaid, uint256 tokensOwed) = lendgine.positions(positionID);

        assertEq(liquidity, k);
        assertEq(rewardPerLiquidityPaid, 0);
        assertEq(tokensOwed, 0);

        (uint256 tickLiquidity, uint256 rewardPerINPaid, uint256 tokensOwedPerLiquidity) = lendgine.ticks(1);

        assertEq(tickLiquidity, k);
        assertEq(rewardPerINPaid, 0);
        assertEq(tokensOwedPerLiquidity, 0);

        // Test global storage values
        assertEq(lendgine.currentTick(), 1);
        assertEq(lendgine.currentLiquidity(), 5 * 10**35);
        assertEq(lendgine.rewardPerINStored(), 0);
        assertEq(lendgine.lastUpdate(), 1);
        assertEq(lendgine.interestNumerator(), 5 * 10**35);
    }

    function testBurnFull() public {
        _burn(10**36, cuh);

        // Test lendgine token
        assertEq(lendgine.totalSupply(), 0 ether);
        assertEq(lendgine.balanceOf(cuh), 0 ether);
        assertEq(lendgine.balanceOf(address(lendgine)), 0 ether);

        // Test pair token
        assertEq(pair.buffer(), 0 ether);

        // Test speculative token
        assertEq(speculative.balanceOf(cuh), 10 ether);
        assertEq(speculative.balanceOf(address(lendgine)), 0);

        (uint256 liquidity, uint256 rewardPerLiquidityPaid, uint256 tokensOwed) = lendgine.positions(positionID);

        assertEq(liquidity, k);
        assertEq(rewardPerLiquidityPaid, 0);
        assertEq(tokensOwed, 0);

        (uint256 tickLiquidity, uint256 rewardPerINPaid, uint256 tokensOwedPerLiquidity) = lendgine.ticks(1);

        assertEq(tickLiquidity, k);
        assertEq(rewardPerINPaid, 0);
        assertEq(tokensOwedPerLiquidity, 0);

        // Test global storage values
        assertEq(lendgine.currentTick(), 1);
        assertEq(lendgine.currentLiquidity(), 0 ether);
        assertEq(lendgine.rewardPerINStored(), 0);
        assertEq(lendgine.lastUpdate(), 1);
        assertEq(lendgine.interestNumerator(), 0);
    }

    function testZeroBurn() public {
        vm.expectRevert(Lendgine.InsufficientOutputError.selector);
        lendgine.burn(cuh);
    }
}
