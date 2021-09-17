pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interface/IAuction.sol";
import "./Auction.sol";

contract AuctionFactory is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    address public feeTo;
    address public feeToSetter;
    uint256 public feeToRate;
    bytes32 public initCodeHash;
    address[] public allAuctions;
    address[] public payTokenList;

    event AuctionCreated(address _auctionOwner, address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType);
    event AddAllowedPayTokens(address token);

    constructor() public {
        feeToSetter = msg.sender;
        initCodeHash = keccak256(abi.encodePacked(type(Auction).creationCode));
        feeTo = 0x30Be031A6F3A07F7B8Bb383FD47c89b0D6F7607a;
        feeToRate = 50;     //this mean 0.005

        payTokenList = [
            0xcea0F3A470b96775A528d9f39Fc33017bae8d0Ba,
            0x84ba9feaf713497e131De44C6197BA5dF599Ae1f,
            0x0000000000000000000000000000000000000000
        ];
    }
    
    function allAuctionsLength() external view returns (uint) {
        return allAuctions.length;
    }

    function createAuction(address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType) external returns (address auction) {

        bytes memory bytecode = type(Auction).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, _tokenId, _initFund, _bidIncrement, _endTime, _payType));
        assembly {
            auction := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IAuction(auction).initialize(msg.sender, _token, _tokenId, _initFund, _bidIncrement, _endTime, _payType);

        allAuctions.push(auction);

        IERC721(_token).transferFrom(msg.sender, auction, _tokenId);

        emit AuctionCreated(msg.sender, _token, _tokenId, _initFund, _bidIncrement, _endTime, _payType);
    }


    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'AuctionFactory: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'AuctionFactory: FORBIDDEN');
        require(_feeToSetter != address(0), "AuctionFactory: FeeToSetter is zero address");
        feeToSetter = _feeToSetter;
    }

    function setFeeToRate(uint256 _rate) external {
        require(msg.sender == feeToSetter, 'AuctionFactory: FORBIDDEN');
        require(_rate > 0, "AuctionFactory: FEE_TO_RATE_OVERFLOW");
	require(_rate < 10000, "AuctionFactory: FEE_TO_RATE_TOO_HIGH");
        feeToRate = _rate;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function auctionFor(address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType) public view returns (address auction) {
        auction = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(_token, _tokenId, _initFund, _bidIncrement, _endTime, _payType)),
                initCodeHash
            ))));
    }


    function getAllAuctions() public view returns (address[] memory) {
        return allAuctions;
    }

    function getPayTokenList() public view returns (address[] memory) {
        return payTokenList;
    }

    function addAllowedPayTokens(address token) external onlyOwner {
        require(token != address(0), "token is zero address");
        if (payTokenIsAllowed(token) == false) {
            payTokenList.push(token);
            emit AddAllowedPayTokens(token);
        }
    }

    function payTokenIsAllowed(address token) public view returns (bool) {
        for (uint256 _index = 0; _index < payTokenList.length; _index++) {
            if (payTokenList[_index] == token) {
                return true;
            }
        }
        return false;
    }
}
