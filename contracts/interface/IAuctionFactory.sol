pragma solidity >=0.5.0 <0.8.0;

interface IAuctionFactory {

    event AuctionCreated(address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType);
    event AddAllowedPayTokens(address token);

    function feeTo() external view returns (address payable);
    function feeToSetter() external view returns (address);
    function feeToRate() external view returns (uint256);

    function allAuctionsLength() external;
    function createAuction(address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType) external;
    function setFeeTo(address _feeTo) external;
    function setFeeToSetter(address _feeToSetter) external;
    function setFeeToRate(uint256 _rate) external;
    function auctionFor(address _token, uint256 _tokenId, uint _initFund, uint _bidIncrement, uint _endTime, uint _payType) external;
    function getAllAuctions() external view returns (address[] memory);
    function getPayTokenList() external view returns (address[] memory);
    function addAllowedPayTokens(address token) external;
    function payTokenIsAllowed(address token) external view returns (bool);
}



