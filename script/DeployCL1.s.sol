// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import 'forge-std/StdJson.sol';
import 'forge-std/Script.sol';

import {CLFactory} from 'contracts/core/CLFactory.sol';
import {NonfungiblePositionManager} from 'contracts/periphery/NonfungiblePositionManager.sol';
import {CLGaugeFactory} from 'contracts/gauge/CLGaugeFactory.sol';
import {CustomSwapFeeModule} from 'contracts/core/fees/CustomSwapFeeModule.sol';
import {CustomUnstakedFeeModule} from 'contracts/core/fees/CustomUnstakedFeeModule.sol';

contract DeployCL1 is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint('PRIVATE_KEY_DEPLOY');
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString('CONSTANTS_FILENAME');
    string public outputFilename = vm.envString('OUTPUT_FILENAME');
    string public jsonConstants;

    // loaded variables
    address public team;
    address public poolFactoryOwner;
    address public feeManager;
    address public notifyAdmin;

    // deployed contracts from DeployCore
    CLFactory public poolFactory;
    NonfungiblePositionManager public nft;
    CLGaugeFactory public gaugeFactory;
    CustomSwapFeeModule public swapFeeModule;
    CustomUnstakedFeeModule public unstakedFeeModule;

    function run() public {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, '/script/constants/');
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        team = abi.decode(vm.parseJson(jsonConstants, '.team'), (address));
        poolFactoryOwner = abi.decode(vm.parseJson(jsonConstants, '.poolFactoryOwner'), (address));
        feeManager = abi.decode(vm.parseJson(jsonConstants, '.feeManager'), (address));
        notifyAdmin = abi.decode(vm.parseJson(jsonConstants, '.notifyAdmin'), (address));

        path = concat(basePath, 'output/DeployCL0-');
        path = concat(path, outputFilename);
        string memory coreOutput = vm.readFile(path);
        poolFactory = CLFactory(abi.decode(vm.parseJson(coreOutput, '.PoolFactory'), (address)));
        nft = NonfungiblePositionManager(abi.decode(vm.parseJson(coreOutput, '.NonfungiblePositionManager'), (address)));
        gaugeFactory = CLGaugeFactory(abi.decode(vm.parseJson(coreOutput, '.GaugeFactory'), (address)));

        vm.startBroadcast(deployerAddress);
        // set nft manager in the factories
        console.log('setting nft manager in the factories');
        console.log('nft: ', address(nft));
        // gaugeFactory.setNonfungiblePositionManager(address(nft));
        gaugeFactory.setNotifyAdmin(notifyAdmin);

        // deploy fee modules
        swapFeeModule = new CustomSwapFeeModule({_factory: address(poolFactory)});
        unstakedFeeModule = new CustomUnstakedFeeModule({_factory: address(poolFactory)});
        poolFactory.setSwapFeeModule({_swapFeeModule: address(swapFeeModule)});
        poolFactory.setUnstakedFeeModule({_unstakedFeeModule: address(unstakedFeeModule)});

        // transfer permissions
        nft.setOwner(team);
        poolFactory.setOwner(poolFactoryOwner);
        poolFactory.setSwapFeeManager(feeManager);
        poolFactory.setUnstakedFeeManager(feeManager);
        vm.stopBroadcast();

        path = concat(basePath, 'output/DeployCL1-');
        path = concat(path, outputFilename);
        vm.writeJson(vm.serializeAddress('', 'SwapFeeModule', address(swapFeeModule)), path);
        vm.writeJson(vm.serializeAddress('', 'UnstakedFeeModule', address(unstakedFeeModule)), path);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}