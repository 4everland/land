import '@nomicfoundation/hardhat-chai-matchers'
import '@nomicfoundation/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
import '@typechain/hardhat'

import 'hardhat-deploy'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import 'hardhat-storage-layout'
import 'solidity-docgen'
import '@matterlabs/hardhat-zksync-solc'
import '@matterlabs/hardhat-zksync-deploy'

import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || './.env'
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) })

const accounts = {
	mnemonic: process.env.MNEMONIC || 'test test test test test test test test test test test test',
}
if (process.env.NODE_ENV != 'build') {
	require('./tasks')
}

const config = {
	zksolc: {
		version: '1.4.0', // Uses latest available in https://github.com/matter-labs/zksolc-bin/
		settings: {},
	},
	solidity: {
		overrides: {},
		compilers: [
			{
				version: '0.8.19',
				settings: {
					optimizer: {
						enabled: true,
						runs: 200,
						details: {
							yul: false
						}
					},
					outputSelection: {
						'*': {
							'*': ['storageLayout'],
						},
					},
				},
			}
		],
	},
	namedAccounts: {
		deployer: 0,
		simpleERC20Beneficiary: 1
	},
	networks: {
		mainnet: {
			url: process.env.MAINNET,
			accounts,
			gas:'auto',
			gasPrice:'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		sepolia: {
			url: 'https://eth-sepolia.g.alchemy.com/v2/BozCNsg-XYuj_WXWdMcHHinrOSC7jQRI',  // The Ethereum Web3 RPC URL (optional).
			zksync: false, // disables zksolc compiler
		},
		zkSyncTestnet: {
			url: 'https://sepolia.era.zksync.dev', // The testnet RPC URL of zkSync Era network.
			ethNetwork: 'sepolia', // The Ethereum Web3 RPC URL, or the identifier of the network (e.g. `mainnet` or `sepolia`)
			zksync: true, // enables zksolc compiler
		},
		zkSyncMainnet: {
			url: 'https://mainnet.era.zksync.io',
			ethNetwork: 'mainnet',
			zksync: true
		},
		localhost: {
			url: 'http://127.0.0.1:8545',
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		hardhat: {
			// forking: {
			// 	enabled: true,
			// 	blockNumber: 113463904,
			// 	url: process.env.MAINNET
			// },
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			chainId: 1337,
			mining: {
				auto: true,
				interval: 2000
			}
		},
		blast:{
			url: 'https://blast.blockpi.network/v1/rpc/public',
			accounts
		},
		'arbitrum-nova': {
			url: 'https://arbitrum-nova.publicnode.com',
			accounts,
			chainId: 42170
		},
		'arbitrum-one': {
			url: 'https://arbitrum-one.publicnode.com',
			accounts,
			chainId: 42161
		},
		'arbitrum-testnet': {
			url: 'https://stylus-testnet.arbitrum.io/rpc',
			accounts,
			chainId: 23011913
		},
		'polygon-zk': {
			url: 'https://polygon-zkevm.blockpi.network/v1/rpc/public',
			accounts,
			chainId: 1101
		},
		'polygon-zk-testnet': {
			url: 'https://rpc.public.zkevm-test.net',
			accounts,
			chainId: 1442
		},
		'opbnb-testnet': {
			url: 'https://opbnb-testnet-rpc.bnbchain.org',
			accounts,
			chainId: 5611,
		},
		'opbnb-mainnet': {
			url: 'https://opbnb-rpc.publicnode.com',
			accounts,
			chainId: 204,
		},
		'linea-testnet': {
			url: 'https://rpc.goerli.linea.build',
			accounts,
			chainId: 59140,
		},
		linea: {
			url: 'https://linea-mainnet.infura.io/v3/b60fe281bce9412991978d81b951b4ec',
			accounts,
			chainId: 59144,
		},
		bsc: {
			url: 'https://binance.nodereal.io',
			accounts,
			chainId: 56,
		},
		chapel: {
			url: 'https://endpoints.omniatech.io/v1/bsc/testnet/public',
			accounts,
			chainId: 97,
		},
		'scroll-testnet': {
			url: 'https://sepolia-rpc.scroll.io/',
			accounts,
			chainId: 534351
		},
		goerli: {
			url: 'https://eth-goerli.api.onfinality.io/public',
			accounts,
			chainId: 5,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		polygon: {
			url: 'https://polygon-bor.publicnode.com',
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		mumbai: {
			url: 'https://rpc.ankr.com/polygon_mumbai',
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000,
		},
		'optimism-dev': {
			url: 'https://optimism.llamarpc.com',
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		'optimism-pro': {
			url: 'https://opt-mainnet.g.alchemy.com/v2/uwFroxk2OBoMpOSrmkuHAOcl1Z_1HQy_',
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		'scroll': {
			url: 'https://scroll.rpc.thirdweb.com',
			accounts,
			gas: 'auto',
			chainId: 534352,
			gasPrice: 'auto',
		},
		'scroll-pro': {
			url: 'https://scroll.rpc.thirdweb.com',
			accounts,
			gas: 'auto',
			chainId: 534352,
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		'zksync-era': {
			url: 'https://mainnet.era.zksync.io',
			chainId: 324,
			accounts
		},
		zkTestnet: {
			url: 'https://testnet.era.zksync.dev',
			accounts
		},
	},
	etherscan: {
		apiKey: {
			mainnet: process.env.APIKEY_MAINNET!,
			arbitrum: process.env.APIKEY_ARBONE,
			arbitrumOne: process.env.APIKEY_ARBONE!,
			arbitrumNova: process.env.APIKEY_ARBNOVA!,
			linea: process.env.APIKEY_LINEA,
			sepolia: process.env.APIKEY_MAINNET!,
			bsc:  process.env.APIKEY_BSC!,
			polygon: process.env.APIKEY_POLYGON!,
			goerli: process.env.APIKEY_GOERLI!,
			bscTestnet: process.env.APIKEY_CHAPEL!,
			polygonMumbai: process.env.APIKEY_MUMBAI!,
			optimisticEthereum: process.env.APIKEY_OP!,
			blast: process.env.APIKEY_BLAST!,
			'opbnb-mainnet': process.env.APIKEY_MAINNET!,
		},
		customChains: [
			{
				network: 'blast',
				chainId: 81457,
				urls: {
					apiURL: 'https://api.blastscan.io/api',
					browserURL: 'https://blastscan.io'
				}
			}
		]
	},
	paths: {
		deploy: 'deploy',
		artifacts: 'artifacts',
		cache: 'cache',
		sources: 'contracts',
		tests: 'tests'
	},
	gasReporter: {
		currency: 'USD',
		gasPrice: 100,
		enabled: process.env.REPORT_GAS ? true : false,
		coinmarketcap: process.env.COINMARKETCAP_API_KEY,
		maxMethodDiff: 10,
	},
	docgen: {
		templates: './hbs',
		root: './',
		theme: 'markdown',
		sourcesDir: './contracts',
		pages: 'files',
		outputDir: './docs'
	},
	typechain: {
		outDir: 'types',
		target: 'ethers-v6',
	},
	mocha: {
		timeout: 0,
	}
}

export default config
