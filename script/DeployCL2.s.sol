// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import 'forge-std/StdJson.sol';
import 'forge-std/Script.sol';

import {CLFactory} from 'contracts/core/CLFactory.sol';
import {MixedRouteQuoterV1} from 'contracts/periphery/lens/MixedRouteQuoterV1.sol';
import {QuoterV2} from 'contracts/periphery/lens/QuoterV2.sol';
import {SwapRouter} from 'contracts/periphery/SwapRouter.sol';

contract DeployCL2 is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint('PRIVATE_KEY_DEPLOY');
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString('CONSTANTS_FILENAME');
    string public outputFilename = vm.envString('OUTPUT_FILENAME');
    string public jsonConstants;

    // loaded variables
    address public weth;
    address public factoryV2;

    // deployed contracts from previous scripts
    CLFactory public poolFactory;
    MixedRouteQuoterV1 public mixedQuoter;
    QuoterV2 public quoter;
    SwapRouter public swapRouter;

    function run() public {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, '/script/constants/');
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        weth = abi.decode(vm.parseJson(jsonConstants, '.WETH'), (address));
        factoryV2 = abi.decode(vm.parseJson(jsonConstants, '.factoryV2'), (address));

        path = concat(basePath, 'output/DeployCL0-');
        path = concat(path, outputFilename);
        string memory coreOutput = vm.readFile(path);
        poolFactory = CLFactory(abi.decode(vm.parseJson(coreOutput, '.PoolFactory'), (address)));

        vm.startBroadcast(deployerAddress);
        mixedQuoter = new MixedRouteQuoterV1({_factory: address(poolFactory), _factoryV2: factoryV2, _WETH9: weth});
        quoter = new QuoterV2({_factory: address(poolFactory), _WETH9: weth});
        swapRouter = new SwapRouter({_factory: address(poolFactory), _WETH9: weth});
        vm.stopBroadcast();

        path = concat(basePath, 'output/DeployCL2-');
        path = concat(path, outputFilename);
        vm.writeJson(vm.serializeAddress('', 'MixedQuoter', address(mixedQuoter)), path);
        vm.writeJson(vm.serializeAddress('', 'Quoter', address(quoter)), path);
        vm.writeJson(vm.serializeAddress('', 'SwapRouter', address(swapRouter)), path);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}