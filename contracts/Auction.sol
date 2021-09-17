pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interface/IAuctionFactory.sol";

contract Auction is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // static
    address public auctionOwner;
    address public factory;
    address public NFTtoken;
    uint public tokenId;
    uint public bidIncrement;
    uint public initFund;
    uint public endTime;
    uint public payType;      //0=NT, 1=USDT, 2=HT
    address public payToken;

    // state
    bool public canceled;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;



    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid);
    event LogWithdrawal();
    event LogCanceled();

    constructor() public {
        factory = msg.sender;

    }

    function initialize(address _auctionOwner, address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType) public onlyOwner {
        require(_auctionOwner != address(0), "auctionOwner is zero address");
        require(_token != address(0), "token is zero address");
        require(_tokenId >= 0, "tokenId: cannot emtpy");
        require(_initFund > 0, "initFund: cannot zero");
        require(_bidIncrement > 0, "bidIncrement: cannot zero");
        require(block.timestamp < _endTime, "endTime must gt now");

	address[] memory payTokenList = IAuctionFactory(factory).getPayTokenList();
        require(_payType < payTokenList.length, "_payType is error");

        auctionOwner = _auctionOwner;
        NFTtoken = _token;
        tokenId = _tokenId;
        //owner = msg.sender;
        bidIncrement = _bidIncrement;
        initFund = _initFund;
        endTime = _endTime;
        payType = _payType;
        payToken = payTokenList[payType];
    }


    function getHighestBid() external view returns (uint)
    {
        return fundsByBidder[highestBidder];
    }


    function placeBid(uint256 bidFund) public 
        payable
        onlyBeforeEnd
        onlyNotOwner
        nonReentrant
        returns (bool success)
    {
        uint256 newBid;

        // reject payments of 0 ETH
        if(payType == 2){
            require(msg.value > 0, "HT cannot emtpy");
            newBid = fundsByBidder[msg.sender] + msg.value;
        }else{
            require(bidFund > 0, "bidFund cannot emtpy");
            newBid = fundsByBidder[msg.sender] + bidFund;
        }

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint highestBid = fundsByBidder[highestBidder];
        if(highestBid <= 0){
            highestBid = initFund;
        }else{
            highestBid = highestBid.add(bidIncrement);
        }
        
        require(newBid >= highestBid, "newBid must gt highestBid and Increment");

        if(payType != 2){
            IERC20(payToken).safeTransferFrom(msg.sender, address(this), bidFund);
        }
        
        fundsByBidder[msg.sender] = newBid;
        highestBidder = msg.sender;
        highestBid = newBid;

        LogBid(msg.sender, newBid, highestBidder, highestBid);
        return true;
    }


    function withdraw() public onlyEndedOrCanceled nonReentrant returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;


        if (msg.sender == auctionOwner) {

	    if(fundsByBidder[highestBidder] <= 0){

		IERC721(NFTtoken).safeTransferFrom(address(this), msg.sender, tokenId);

	    }else{
		    address payable feeBeneficiary = IAuctionFactory(factory).feeTo();
		    uint256 feeRate = IAuctionFactory(factory).feeToRate();

		    withdrawalAccount = highestBidder;
		    withdrawalAmount = fundsByBidder[highestBidder];
		    require(withdrawalAmount > 0, "withdrawalAmount is empty");

		    ownerHasWithdrawn = true;
		    fundsByBidder[withdrawalAccount] = 0;

		    uint256 feeAmount = withdrawalAmount.mul(feeRate).div(10000);

		    if(payType == 2){
			require(msg.sender.send(withdrawalAmount.sub(feeAmount)), "HT transfer fail");
			require(feeBeneficiary.send(feeAmount), "HT transfer to feeBeneficiary fail");
		    }else{
			IERC20(payToken).safeTransfer(msg.sender, withdrawalAmount.sub(feeAmount));
			IERC20(payToken).safeTransfer(feeBeneficiary, feeAmount);
		    }
	    }

        } else if (msg.sender == highestBidder) {

            IERC721(NFTtoken).safeTransferFrom(address(this), msg.sender, tokenId);

        } else {

            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

            require(withdrawalAmount > 0, "withdrawalAmount is empty");

            fundsByBidder[withdrawalAccount] = 0;

            if(payType == 2){
                require(msg.sender.send(withdrawalAmount), "HT transfer fail");
            }else{
                IERC20(payToken).safeTransfer(msg.sender, withdrawalAmount);
            }
        }


        LogWithdrawal();

        return true;
    }

    function getfundsByBidder(address userAddress) external view returns (uint256)
    {
        require(userAddress != address(0), "userAddress is zero address");
        return fundsByBidder[userAddress];
    }



    modifier onlyNotOwner {
        require(msg.sender != auctionOwner, "onlyNotOwner");
        _;
    }

    modifier onlyBeforeEnd {
        require(block.timestamp < endTime, "auction is close");
        _;
    }

    modifier onlyEndedOrCanceled {
        require(block.timestamp > endTime, "auction is not close");
        _;
    }

}



