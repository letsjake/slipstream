// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import 'forge-std/StdJson.sol';
import 'forge-std/Script.sol';

import {CLPool} from 'contracts/core/CLPool.sol';
import {CLFactory} from 'contracts/core/CLFactory.sol';
import {NonfungibleTokenPositionDescriptor} from 'contracts/periphery/NonfungibleTokenPositionDescriptor.sol';
import {NonfungiblePositionManager} from 'contracts/periphery/NonfungiblePositionManager.sol';
import {CLGauge} from 'contracts/gauge/CLGauge.sol';
import {CLGaugeFactory} from 'contracts/gauge/CLGaugeFactory.sol';

contract DeployCL0 is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint('PRIVATE_KEY_DEPLOY');
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public constantsFilename = vm.envString('CONSTANTS_FILENAME');
    string public outputFilename = vm.envString('OUTPUT_FILENAME');
    string public jsonConstants;

    // loaded variables
    address public weth;
    address public voter;
    string public nftName;
    string public nftSymbol;

    // deployed contracts
    CLPool public poolImplementation;
    CLFactory public poolFactory;
    NonfungibleTokenPositionDescriptor public nftDescriptor;
    NonfungiblePositionManager public nft;
    CLGauge public gaugeImplementation;
    CLGaugeFactory public gaugeFactory;

    function run() public {
        string memory root = vm.projectRoot();
        string memory basePath = concat(root, '/script/constants/');
        string memory path = concat(basePath, constantsFilename);
        jsonConstants = vm.readFile(path);

        weth = abi.decode(vm.parseJson(jsonConstants, '.WETH'), (address));
        voter = abi.decode(vm.parseJson(jsonConstants, '.Voter'), (address));
        nftName = abi.decode(vm.parseJson(jsonConstants, '.nftName'), (string));
        nftSymbol = abi.decode(vm.parseJson(jsonConstants, '.nftSymbol'), (string));

        require(address(voter) != address(0));

        vm.startBroadcast(deployerAddress);
        // deploy pool + factory
        poolImplementation = new CLPool();
        poolFactory = new CLFactory({_voter: voter, _poolImplementation: address(poolImplementation)});

        // deploy gauges
        gaugeImplementation = new CLGauge();
        gaugeFactory = new CLGaugeFactory({_voter: voter, _implementation: address(gaugeImplementation)});

        // deploy nft contracts
        nftDescriptor = new NonfungibleTokenPositionDescriptor({
            _WETH9: address(weth),
            _nativeCurrencyLabelBytes: bytes32('ETH')
        });
        nft = new NonfungiblePositionManager({
            _factory: address(poolFactory),
            _WETH9: address(weth),
            _tokenDescriptor: address(nftDescriptor),
            name: nftName,
            symbol: nftSymbol
        });
        vm.stopBroadcast();

        path = concat(basePath, 'output/DeployCL0-');
        path = concat(path, outputFilename);
        vm.writeJson(vm.serializeAddress('', 'PoolImplementation', address(poolImplementation)), path);
        vm.writeJson(vm.serializeAddress('', 'PoolFactory', address(poolFactory)), path);
        vm.writeJson(vm.serializeAddress('', 'NonfungibleTokenPositionDescriptor', address(nftDescriptor)), path);
        vm.writeJson(vm.serializeAddress('', 'NonfungiblePositionManager', address(nft)), path);
        vm.writeJson(vm.serializeAddress('', 'GaugeImplementation', address(gaugeImplementation)), path);
        vm.writeJson(vm.serializeAddress('', 'GaugeFactory', address(gaugeFactory)), path);
        
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}