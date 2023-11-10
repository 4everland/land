import '@nomicfoundation/hardhat-chai-matchers'
import '@nomicfoundation/hardhat-ethers'
import '@nomicfoundation/hardhat-verify'
import '@typechain/hardhat'

import 'hardhat-deploy'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import 'hardhat-storage-layout'
import 'solidity-docgen'

import { config as dotenvConfig } from 'dotenv'
import { resolve } from 'path'

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || './.env'
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) })

const accounts = {
	mnemonic: process.env.MNEMONIC || 'test test test test test test test test test test test test',
}

const config = {
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
		localhost: {
			url: 'http://127.0.0.1:8545',
			accounts,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		hardhat: {
			forking: {
				enabled: true,
				url: process.env.MAINNET
			},
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
		arbitrum: {
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
			url: 'https://opbnb-mainnet-rpc.bnbchain.org',
			accounts,
			chainId: 204,
		},
		// depreacated
		// 'opbnb-testnet-pro': {
		// 	url: 'https://opbnb-testnet-rpc.bnbchain.org',
		// 	accounts,
		// 	chainId: 5611,
		// },
		'linea-testnet': {
			url: 'https://rpc.goerli.linea.build',
			accounts,
			chainId: 59140,
		},
		'linea': {
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
		'scroll-mainnet': {
			url: 'https://rpc.scroll.io/',
			accounts,
			chainId: 534352
		},
		goerli: {
			url: 'https://rpc.goerli.eth.gateway.fm',
			accounts,
			chainId: 5,
			gas: 'auto',
			gasPrice: 'auto',
			gasMultiplier: 1.3,
			timeout: 100000
		},
		polygon: {
			url: 'https://rpc-mainnet.matic.network',
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
		}
	},
	etherscan: {
		apiKey: {
			mainnet: process.env.APIKEY_MAINNET!,
			bsc:  process.env.APIKEY_BSC!,
			polygon: process.env.APIKEY_POLYGON!,
			goerli: process.env.APIKEY_GOERLI!,
			bscTestnet: process.env.APIKEY_CHAPEL!,
			polygonMumbai: process.env.APIKEY_MUMBAI!
		}
	},
	paths: {
		deploy: 'deploy',
		artifacts: 'artifacts',
		cache: 'cache',
		sources: 'contracts',
		tests: 'test'
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
