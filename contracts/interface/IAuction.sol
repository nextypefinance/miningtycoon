pragma solidity >=0.5.0 <0.8.0;

interface IAuction {

    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid);
    event LogWithdrawal();
    event LogCanceled();

    function initialize(address _auctionOwner, address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType) external;
    function getHighestBid() external;
    function placeBid(uint256 bidFund) external;
    function withdraw() external;
    function getfundsByBidder(address userAddress) external;
}



