import '@nomicfoundation/hardhat-ethers'
import 'hardhat-deploy'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const deployFuc: DeployFunction = async (env: HardhatRuntimeEnvironment) => {
	const { deployments, ethers } = env
	const { deploy } = deployments
	const signers = await ethers.getSigners()
	const from = await signers[0].getAddress()
	await deploy('MockUSDT', {
		from
	})

}

deployFuc.tags = ['MockUSDT']
export default deployFuc

