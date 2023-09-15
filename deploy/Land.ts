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
	const dai = await deployments.get('MockDAI')
	const args = [
		core.address,
		[usdc.address, dai.address]
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

