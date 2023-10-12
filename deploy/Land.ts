import '@nomicfoundation/hardhat-ethers'
import 'hardhat-deploy'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const deployFuc: DeployFunction = async (env: HardhatRuntimeEnvironment) => {
	const { deployments, ethers } = env
	const { deploy } = deployments
	const signers = await ethers.getSigners()
	const from = await signers[0].getAddress()
	const core = await deployments.get('LandCore')
	const usdc = await deployments.get('MockUSDC')
	const usdt = await deployments.get('MockUSDT')
	const dai = await deployments.get('MockDAI')
	const coins = [usdc.address, usdt.address, dai.address]
	// const coins = ['0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xdAC17F958D2ee523a2206206994597C13D831ec7', '0x6B175474E89094C44Da98b954EedeAC495271d0F'] ethereum
	// const coins = ['0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', '0xc2132D05D31c914a87C6611C10748AEb04B58e8F', '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063'] polygon
	// const coins = ['0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d', '0x55d398326f99059fF775485246999027B3197955', '0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3'] bsc
	// const coins = ['0xaf88d065e77c8cC2239327C5EDb3A432268e5831', '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9', '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1'] arbitrum
	// const coins = ['0x176211869cA2b568f2A7D4EE941E073a821EE1ff', '0xA219439258ca9da29E9Cc4cE5596924745e12B93', '0x4AF15ec2A0BD43Db75dd04E62FAA3B8EF36b00d5'] linea
	// const coins = ['0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4'] zksync

	const args = [
		core.address,
		coins
	]
	await deploy('Land', {
		from,
		log: true,
		proxy: {
			owner: from,
			proxyContract: 'TransparentUpgradeableProxy',
			viaAdminContract: { name: 'ProxyAdmin' },
			execute: {
				init: {
					methodName: 'initialize',
					args
				}
			}
		}
	})

}

deployFuc.tags = ['Land']
export default deployFuc

