import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import fs from "fs";

const privateKey = fs.readFileSync(".secret").toString();
const appId = fs.readFileSync(".appId").toString();

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      url: `https://rpc-mumbai.maticvigil.com/v1/${appId}`,
      accounts: [privateKey],
    },
    mainnet: {
      url: `https://rpc-mainnet.maticvigil.com/v1/${appId}`,
      accounts: [privateKey],
    }
  },
  solidity: "0.8.4",
};

export default config;
