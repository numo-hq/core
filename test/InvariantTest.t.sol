pragma solidity ^0.8.4;

import "forge-std/console2.sol";

import { TestHelper } from "./utils/TestHelper.sol";
import { CallbackHelper } from "./utils/CallbackHelper.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

import { LendgineAddress } from "../src/libraries/LendgineAddress.sol";

import { Factory } from "../src/Factory.sol";
import { Lendgine } from "../src/Lendgine.sol";

contract InvariantTest is TestHelper {
    function setUp() public {
        _setUp();
    }

    function testLiquidityAmount() public {
        _pairMint(1 ether, 1 ether, cuh);

        assertEq(pair.totalSupply(), k);
        assertEq(pair.buffer(), k);
    }

    function testBurnAmount() public {
        _pairMint(1 ether, 1 ether, cuh);
        // TODO: is there a precision loss here
        uint256 amount0 = 1 ether;
        uint256 amount1 = 1 ether;
        pair.burn(cuh, amount0, amount1);

        assertEq(speculative.balanceOf(cuh), 1 ether);
        assertEq(base.balanceOf(cuh), 1 ether);

        assertEq(pair.totalSupply(), 0);
        assertEq(pair.buffer(), 0);
    }

    function testDouble() public {
        _mintMaker(1 ether, 1 ether, 1, cuh);
        _pairMint(1_000_000, 1_000_000, dennis);

        // TODO: precision lost with small amounts of inputs
        uint256 k2 = 10**15 + 5 * 10**15 - 10**3 / 4;

        assertEq(pair.totalSupply(), k + k2);
        assertEq(pair.buffer(), k2);

        pair.burn(dennis, 1_000_000, 1_000_000);

        assertEq(speculative.balanceOf(dennis), 1_000_000);
        assertEq(base.balanceOf(dennis), 1_000_000);

        assertEq(pair.buffer(), 0);
        assertEq(pair.totalSupply(), k);

        _burnMaker(k, 1, cuh);

        assertEq(pair.buffer(), k);
        assertEq(pair.totalSupply(), k);

        pair.burn(cuh, 1 ether, 1 ether);

        assertEq(pair.totalSupply(), 0);
        assertEq(pair.buffer(), 0);
    }

    struct SwapCallbackData {
        LendgineAddress.LendgineKey key;
        address payer;
        uint256 amount0In;
        uint256 amount1In;
    }

    function SwapCallback(
        uint256,
        uint256,
        bytes calldata data
    ) external {
        SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));
        // CallbackValidation.verifyCallback(factory, decoded.poolKey);

        if (decoded.amount0In > 0) pay(ERC20(decoded.key.token0), decoded.payer, msg.sender, decoded.amount0In);
        if (decoded.amount1In > 0) pay(ERC20(decoded.key.token1), decoded.payer, msg.sender, decoded.amount1In);
    }

    function testSwap() public {
        _pairMint(0 ether, 2 ether, cuh);

        uint256 amount1Out = 0.00001 ether;

        uint256 a = (amount1Out * upperBound) / 1 ether;

        uint256 b = ((amount1Out**2) / 4) / 1 ether;

        uint256 c = (2 ether * amount1Out) / 2 ether;

        uint256 amount0In = a + b - c;

        speculative.mint(cuh, amount0In);

        vm.prank(cuh);
        speculative.approve(address(this), amount0In);

        pair.swap(
            cuh,
            0,
            amount1Out,
            abi.encode(SwapCallbackData({ key: key, payer: cuh, amount0In: amount0In, amount1In: 0 }))
        );
    }

    // test 2/3 1/3 burn
}
