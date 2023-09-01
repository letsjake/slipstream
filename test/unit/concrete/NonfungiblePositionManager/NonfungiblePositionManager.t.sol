pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../../BaseFixture.sol";

contract NonfungiblePositionManagerTest is BaseFixture {
    UniswapV3Pool public pool;
    CLGauge public gauge;

    function setUp() public virtual override {
        super.setUp();

        pool = UniswapV3Pool(
            poolFactory.createPool({tokenA: address(token0), tokenB: address(token1), tickSpacing: TICK_SPACING_60})
        );
        gauge = CLGauge(voter.gauges(address(pool)));

        vm.startPrank(users.alice);
        deal({token: address(token0), to: users.alice, give: TOKEN_1 * 10});
        deal({token: address(token1), to: users.alice, give: TOKEN_1 * 10});
        token0.approve(address(nft), type(uint256).max);
        token1.approve(address(nft), type(uint256).max);
        token0.approve(address(gauge), type(uint256).max);
        token1.approve(address(gauge), type(uint256).max);
    }
}
