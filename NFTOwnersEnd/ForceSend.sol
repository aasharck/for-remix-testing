// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../openzeppelin/token/ERC20/IERC20.sol";

interface IVaultInterface{
    function supplyFundsToCampaign(uint256 _amount) external;
    function mintGovernanceTokens(uint256 _amount) external;
}

contract ForceSend{

    // TODO: Change Vault Address
    address public vaultAddress = address(0);
    IVaultInterface public vaultContract;
    IERC20 public USDC;


    constructor() {
        vaultContract = IVaultInterface(vaultAddress);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    modifier sendToVault(uint256 _amount){
        USDC.transferFrom(msg.sender, vaultAddress, _amount);
        vaultContract.supplyFundsToCampaign(_amount);
        vaultContract.mintGovernanceTokens(_amount);
        _;
    }
}