import { ethers } from 'hardhat'
import { parseEther } from 'ethers/lib/utils'
import {encodePriceSqrt} from './shared/utilities'
describe("Local contract test", function() {

    it("Deply & test",async function () {
      
      const ERC20 = await ethers.getContractFactory("t0");
      const token0 = await ERC20.deploy(); 
      const ERC201 = await ethers.getContractFactory("t1");
      const token1 = await ERC201.deploy(); 
      const poolDep = await ethers.getContractFactory("AlgebraPoolDeployer");
      const pooldep = await poolDep.deploy();
      
      
      const V3fact = await ethers.getContractFactory("AlgebraFactory");
      const factory = await V3fact.deploy(pooldep.address,pooldep.address);
      
      const localContract = await  ethers.getContractFactory("V3");
      const v3 = await localContract.deploy(factory.address);
      
      

      await token0.mint(parseEther("10000"));
      await token1.mint(parseEther("10000"));
      await token0.approve(v3.address,parseEther("10000"));
      await token1.approve(v3.address,parseEther("10000"));
      
      await pooldep.setFactory(factory.address);
      await v3.create(token0.address,token1.address,encodePriceSqrt(parseEther("10"),parseEther("10")))
      await v3.addLiquidity(-120, 120, parseEther("10"),parseEther("10"));
      await v3.swap(true,false,parseEther("1"));
      await v3.swap(false,false,parseEther("1"));
      await v3.swap(true,true,parseEther("1"));
      await v3.swap(false,true,parseEther("1"));
      await v3.burnLiquidity(-120,120,parseEther("10"),parseEther("10"));
      await v3.collect(120,-120,parseEther("12"),parseEther("12"))
    });



});
