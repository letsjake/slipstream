pragma solidity ^0.7.6;
pragma abicoder v2;

import {UniswapV3FactoryTest} from './UniswapV3Factory.t.sol';

contract EnableTickSpacingTest is UniswapV3FactoryTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank({msgSender: users.owner});
    }

    function test_RevertIf_NotOwner() public {
        vm.expectRevert();
        changePrank({msgSender: users.charlie});
        poolFactory.enableTickSpacing({tickSpacing: 250, fee: 5_000});
    }

    function test_RevertIf_TickSpacingTooSmall() public {
        vm.expectRevert();
        poolFactory.enableTickSpacing({tickSpacing: 0, fee: 5_000});
    }

    function test_RevertIf_TickSpacingTooLarge() public {
        vm.expectRevert();
        poolFactory.enableTickSpacing({tickSpacing: 16_834, fee: 5_000});
    }

    function test_RevertIf_TickSpacingAlreadyEnabled() public {
        poolFactory.enableTickSpacing({tickSpacing: 250, fee: 5_000});
        vm.expectRevert();
        poolFactory.enableTickSpacing({tickSpacing: 250, fee: 5_000});
    }

    function test_RevertIf_FeeTooHigh() public {
        vm.expectRevert();
        poolFactory.enableTickSpacing({tickSpacing: 250, fee: 1_000_000});
    }

    function test_EnableTickSpacing() public {
        vm.expectEmit(true, false, false, false, address(poolFactory));
        emit TickSpacingEnabled({tickSpacing: 250, fee: 5_000});
        poolFactory.enableTickSpacing({tickSpacing: 250, fee: 5_000});

        assertEqUint(poolFactory.tickSpacingToFee(250), 5_000);
        assertEq(poolFactory.tickSpacings().length, 4);
        assertEq(poolFactory.tickSpacings()[3], 250);

        createAndCheckPool({factory: poolFactory, token0: TEST_TOKEN_0, token1: TEST_TOKEN_1, tickSpacing: 250});
    }
}
