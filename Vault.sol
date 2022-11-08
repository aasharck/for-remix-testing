// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC721/IERC721.sol";


//For creating a Gnosis Multisig Wallet
import "safe-contracts/proxies/GnosisSafeProxyFactory.sol";

import "./CampaignFactory.sol";


contract Vault{
    uint256 campaignCount;
    //TODO: Change network accordingly
    //USDC Mainnet
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    //USDC Goerli
    // IERC20 public USDC = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
    
    struct Campaign {
        address nftCreator;
        address nftContractAddress;
        CampaignFactory campaign;
        address multisig;
        uint256 currentStage;
        uint256 totalStages;
        uint128 nftsMinted;
        uint256[] fundsPerStage;
        uint256 currentFunds;
        uint256 totalFundsRequired;
        bool campaignRemoved;
    }
    mapping(address => Campaign) public allCampaigns;
    mapping(address => bool) public timelocks;    
    mapping(address => mapping(address => bool)) public fundsClaimedAfterCampaignRemoval;

    //for Gnosis
    address public immutable masterCopyAddress;
    GnosisSafeProxyFactory public immutable proxyFactory;


    struct ForGovToken {
        string _govTokenName;
        string _govTokenSymbol;
    }

    struct ForGovernor{
        uint256 _quorumPercentage;
        uint256 _votingPeriod;
        uint256 _votingDelay;
    }

    struct MultiSig{
        address[] _signatories;
        uint256 _quorum;
    }

    constructor() {
        proxyFactory = GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        masterCopyAddress = 0x3E5c63644E683549055b9Be8653de26E0B4CD36E;
    }

    // // Precompute the contract address of Timelock and GovernanceToken contract
    // // TODO: should precomuping feature be here or in a library?
    // function precomputeAddressOfTimelock() private view returns(address) {
    //     bytes memory creationCode = type(TimeLock).creationCode;
    //     // TODO: pass in correct arguements here for TimeLock instead of 1 ,[] ,[]
    //     bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(1, [], []));

    //     // TODO: possibly change salt to other number. address(this) is address of deployer
    //     bytes32 hash = keccak256(
    //         abi.encodePacked(
    //             bytes1(0xff), address(this), 777, keccak256(bytecode)
    //         )
    //     );
    //     return address(uint160(uint(hash)));
    // }

    // function precomputeAddressOfGovernanceToken() private view returns(address) {
    //     bytes memory creationCode = type(GovernanceToken).creationCode;
    //     // TODO: pass in correct arguements here for GovernanceToken
    //     bytes memory bytecode = abi.encodePacked(creationCode, abi.encode("SampleName", "SampleSymol"));

    //     // TODO: possibly change salt to other number. address(this) is address of deployer
    //     bytes32 hash = keccak256(
    //         abi.encodePacked(
    //             bytes1(0xff), address(this), 777, keccak256(bytecode)
    //         )
    //     );
    //     return address(uint160(uint(hash)));
    // }

    struct timelockStruct{
        uint256 _minDelay;
        address[] _proposers;
        address[] _executors;
    }


    //setting up a new campaign
    function setupCampaign(
        address _nftContractAddress,
        timelockStruct memory _timelockStruct,
        uint256 _totalStages,
        uint256[] calldata _fundsPerStage,
        uint256 _totalFundsRequired,
        MultiSig calldata _multisig
        ) external {
        // require(_fundsPerStage.length == _totalStages, "Error! FundsPerStage not matching the no of stages");
        require(_totalStages > 0 && _totalFundsRequired > 0, "totalStages or TotalFundsRequired cannot be 0");

        
        //create and deploy Governance Token contract
        // GovernanceToken newGovToken = DeployGovToken.createGovTokenContract(_govTok);

        // //create and deploy Timelock contract
        // TimeLock newTimelock = DeployTimelock.createTimelockContract(_minDelay);
        // timelocks[address(newTimelock)] = true;
    
        // //create and deploy Governor Contract
        // GovernorContract newGovernor = DeployGovernor.createGovernorContract(newGovToken, newTimelock, _GovernorCont, campaignCount, address(this));
        
        // TODO: pass the parameters passed in this function when declaring Campaign Factory
        // address timeLockContractAddress = precomputeAddressOfTimelock();
        // address governanceTokenContractAddress  = precomputeAddressOfGovernanceToken();

        // TODO: Will Change this
        CampaignFactory newCampaign = new CampaignFactory(
            _nftContractAddress,
            _timelockStruct,
            5, 10, 10, address(this)
        );

        //create and deploy nft contract
        // NftContract newNftContract = DeployNft.createNftContract(campaignCount,_nftCont,address(this),address(newGovToken));
        // nftContracts[address(newNftContract)] = true;

        //creating multisig
        // TODO: 
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _multisig._signatories,
            _multisig._quorum,
            address(0x0),
            new bytes(0),
            address(0x0),
            address(0x0),
            0,
            address(0x0)
        );
        address newMultisig = address(proxyFactory.createProxy(masterCopyAddress, initializer));

        
        // TODO: Check if this is needed!!! making NftCreator the owner of nftContract
        // newNftContract.transferOwnership(msg.sender);

        // TODO: Create new campaign using campaign factory
        //Storing this particular campaign
        Campaign memory newCampaignStruct = Campaign(
            msg.sender,
            _nftContractAddress,
            newCampaign,
            newMultisig,
            1,
            _totalStages,
            0,
            _fundsPerStage,
            0,
            _totalFundsRequired,
            false
        );
        allCampaigns[_nftContractAddress] = newCampaignStruct;
    }

    function releaseFunds(address _nftContractAddress) external  {
        require(timelocks[msg.sender] == true, "You are not authorized");
        Campaign memory thisCampaign = allCampaigns[_nftContractAddress];
        USDC.transfer(thisCampaign.multisig, thisCampaign.fundsPerStage[thisCampaign.currentStage - 1]);
        allCampaigns[_nftContractAddress].currentStage++;
    }

    function removeCampaign(address _nftContractAddress) external {
        require(timelocks[msg.sender] == true, "You are not authorized");
        allCampaigns[_nftContractAddress].campaignRemoved = true;
    }

    //to withdraw funds when the campaign is removed
    function withdrawFundsAfterCampaignRemoval(address _nftContractAddress) external {
        IERC721 nftContract = IERC721(_nftContractAddress);
        require(nftContract.balanceOf(msg.sender) > 0, "You are not Authorized");
        require(allCampaigns[_nftContractAddress].campaignRemoved == true, "the campaign is not removed yet");
        require(fundsClaimedAfterCampaignRemoval[msg.sender][_nftContractAddress] = false, "You have already claimed once");
        fundsClaimedAfterCampaignRemoval[msg.sender][_nftContractAddress] = true;
        uint256 totalNftsOwnedByUser = nftContract.balanceOf(msg.sender);
        uint256 totalAmountInUSDC = allCampaigns[_nftContractAddress].currentFunds;
        uint256 withdrawAmount = (totalAmountInUSDC*totalNftsOwnedByUser)/allCampaigns[_nftContractAddress].nftsMinted;
        USDC.transfer(msg.sender, withdrawAmount);
    }


    function getCurrentStage(address _nftContractAddress) external view returns(uint256){
        return allCampaigns[_nftContractAddress].currentStage;
    }

     function supplyFundsToCampaign(uint256 _amount) external{
        require(msg.sender == allCampaigns[msg.sender].nftContractAddress, "You are not authorized");
        allCampaigns[msg.sender].currentFunds += _amount;
        // incrementing the no of minted nfts
        allCampaigns[msg.sender].nftsMinted++;
    }

    function mintGovernanceTokens(uint256 _amount) external{
        require(msg.sender == allCampaigns[msg.sender].nftContractAddress, "You are not authorized");
        // mint some governance token to the sender
        CampaignFactory campaignFactory = allCampaigns[msg.sender].campaign;
        uint256 rate = _amount * 10 ** 12;
        campaignFactory.mint(tx.origin, rate);
    }

}
