// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GovernanceToken.sol";
import "./Timelock.sol";
import "./GovernorContract.sol";
import "./Vault.sol";

contract CampaignFactory is GovernanceToken ,TimeLock, GovernorContract {

    constructor(
        address _nftContractAddress,
        Vault.timelockStruct memory _timelockStruct,
        uint256 _quorumPercentage, 
        uint256 _votingPeriod,
        uint256 _votingDelay,
        address _vault
    ) 
        TimeLock(_timelockStruct)
        GovernorContract(
            _quorumPercentage, 
            _votingPeriod,
            _votingDelay,
            _nftContractAddress,
            _vault
        )
        GovernanceToken("", "")
    {
        // TODO: grant roles in timelock
        // TimeLock newTimelock;
        // newTimelock.grantRole(newTimelock.PROPOSER_ROLE(), address(this));
        // newTimelock.grantRole(newTimelock.EXECUTOR_ROLE(), address(0));
        // //Revoking role here
        // newTimelock.revokeRole(newTimelock.TIMELOCK_ADMIN_ROLE(), msg.sender);
        // TODO: making nftContract the owner of GovernanceToken Contract
        // newGovToken.transferOwnership(address(newNftContract));
    }


    function _domainSeparatorV4() public override(EIP712,EIP712_NoConst) view returns (bytes32) {
        return super._domainSeparatorV4();
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) public virtual override(EIP712,EIP712_NoConst) view returns (bytes32) {
        return super._buildDomainSeparator(typeHash, nameHash, versionHash);
    }

    function _hashTypedDataV4(bytes32 structHash) public virtual override(EIP712,EIP712_NoConst) view returns (bytes32) {
        return super._hashTypedDataV4(structHash);
    }


    // TODO: not sure if  onERC721Received, onERC1155Received, onERC1155BatchReceived, supportsInterface, and receive are imported correctly
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(TimelockController, Governor) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override(TimelockController, Governor) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override(TimelockController, Governor) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(TimelockController, GovernorContract) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    receive() external payable override(TimelockController, Governor) {
        require(_executor() == address(this));
    }


    // TODO: these 3 -  _afterTokenTransfer  _mint and _burn are from gov token contract. Are they a must?
    function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(GovernanceToken) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(GovernanceToken) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(GovernanceToken) {
    super._burn(account, amount);
  }

    //  TODO: change the return value of this name() function
    //We have 2 function with same function signature (meaning name and arguments).

    // I'm taking about the 

    // function name() public view virtual override returns (string memory) function

    // Both in 
    // GovernanceToken <- ERC20Votes <- ERC20Permit <- ERC20

    // and in

    // GovernorContract  <- Governor
  function name() public view virtual override(ERC20, Governor, IGovernor) returns (string memory) {
        return "";
    }
}   