pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTTransaction is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    
    // order id
    Counters.Counter public _orderIds;
    
    string public name = "NFT Transaction";
    
    address[] public allowedPayTokens;
    
    address public HTTOKENADDRESS;
    
    // fee pay token list (token > fee)
    mapping(address => uint256) public feePayTokenList;
    
    address public feeTo;
    
    constructor() public {
        feeTo = _msgSender();
    }
    
    // fee
    event AddAllowedPayTokens(address token);
    event SetPayTokenFee(address token, uint256 amount);
    
    // order
    event SoldOrder(address nftToken, uint256 tokenID, address payToken, uint256 payAmount);
    event SoldOutOrder(uint256 orderID);
    event PurchaseOrder(uint256 orderID);
    
    // token allow
    function addAllowedPayTokens(address token) public onlyOwner {
        require(token != address(0), "token is zero address");
        if (payTokenIsAllowed(token) == false) {
            allowedPayTokens.push(token);
            emit AddAllowedPayTokens(token);
        }
    }

    // check pay token allow
    function payTokenIsAllowed(address token) public view returns (bool) {
        for (uint256 _index = 0; _index < allowedPayTokens.length; _index++) {
            if (allowedPayTokens[_index] == token) {
                return true;
            }
        }
        return false;
    }
    
    // get pay token 
    function getPayTokenType(address token) public view returns (uint256) {
        require(payTokenIsAllowed(token) == true, "token is not allowed");
        
        for (uint256 _index = 0; _index < allowedPayTokens.length; _index++) {
            if (allowedPayTokens[_index] == token) {
                return _index;
            }
        }
    }
    
    // set HT token address
    function setHTTokenAddress(address token) public onlyOwner {
        require(token != address(0), "token is zero address");
        require(payTokenIsAllowed(token) == true, "token is not allowed");
        
        HTTOKENADDRESS = token;
    }
    
    // set fee to address
    function setFeeToAddress(address _feeTo) public onlyOwner {
        require(_feeTo != address(0), "_feeTo is zero address");
        feeTo = _feeTo;
    }
    
    // set pay token fee
    function setPayTokenFee(address token, uint256 amount) public onlyOwner {
        require(token != address(0), "token is zero address");
        require(payTokenIsAllowed(token) == true, "token is not allowed");
        
        feePayTokenList[token] = amount;
        emit SetPayTokenFee(token, amount);
    }
    
    // get pay token fee
    function getPayTokenFee(address token) public view returns (uint256) {
        return feePayTokenList[token];
    }
    
    // order info
    struct OrderInfo{
        uint256 OrderId;
        address OrderOwner;
        address NFTToken;
        uint256 NFTTokenID;
        uint256 PayTokenType;
        uint256 PayAmount;
        uint256 SoldStatus;// 0-sold out, 1-sold, 2-be sold
    }
    
    // order list (orderID > orderInfo)
    mapping(uint256 => OrderInfo) public orderList;
    
    // order id list
    uint256[] public ordersIdList;
    
    // order id list (orderID > order owner)
    mapping(uint256 => address) public orderOfOwner;
    
    // check orderid is existed
    function orderIdIsExisted(uint256 orderID) public view returns (bool){
        bool isExisted = false;
        if (orderList[orderID].OrderId == orderID) {
            return true;
        }
        return isExisted;
    }
    
    // sold order
    function soldOrder(address nftToken, uint256 tokenID, address payToken, uint256 payAmount) public nonReentrant {
        require(nftToken != address(0), "nft address is zero address");
        require(payToken != address(0), "pay token address is zero address");
        require(nftToken != payToken, "nftToken and payToken is same");
        require(payAmount > 0, "pay amount cannot be 0");
        require(payTokenIsAllowed(payToken) == true, "pay token is not allowed");
        require(IERC721(nftToken).ownerOf(tokenID) == msg.sender, "nft tokenID is error");
        
        _orderIds.increment();
        uint256 newOrderId = _orderIds.current();
        
        if( !orderIdIsExisted(newOrderId) ){
            IERC721(nftToken).transferFrom(msg.sender, address(this), tokenID);
            
            orderList[newOrderId].OrderId = newOrderId;
            orderList[newOrderId].OrderOwner = msg.sender;
            orderList[newOrderId].NFTToken = nftToken;
            orderList[newOrderId].NFTTokenID = tokenID;
            orderList[newOrderId].PayTokenType = getPayTokenType(payToken);
            orderList[newOrderId].PayAmount = payAmount;
            orderList[newOrderId].SoldStatus = 1;
            
            ordersIdList.push(newOrderId);
            orderOfOwner[newOrderId] = msg.sender;
            
            emit SoldOrder(nftToken, tokenID, payToken, payAmount);
        }
    }
    
    // sold out order
    function soldOutOrder(uint256 orderID) public nonReentrant {
        require(orderID > 0, "order id cannot be 0");
        require(orderOfOwner[orderID] == msg.sender, "address is not the seller");
        require(orderIdIsExisted(orderID) == true, "order is not existed");
        require(orderList[orderID].SoldStatus == 1, "order cannot sold out");
        
        orderList[orderID].SoldStatus = 0;
        
        address _NFTToken = orderList[orderID].NFTToken;
        uint256 _NFTTokenID = orderList[orderID].NFTTokenID;
        IERC721(_NFTToken).safeTransferFrom(address(this), msg.sender, _NFTTokenID);
        
        emit SoldOutOrder(orderID);
    }
    
    // amoun mul
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod (x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    // amount mul + div
    function mulDiv(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul (x, y);
        require (h < z);
        
        uint256 mm = mulmod (x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        
        return l * r;
    }
    
    // calculate arrival amount
    function calculateArrivalAmount(uint256 amount, address token) public view returns (uint256 tokenFee, uint256 amountValid, uint256 rate) {
        require(amount > 0, "amount cannot be 0");
        require(token != address(0), "token is zero address");
        require(payTokenIsAllowed(token) == true, "token is not allowed");
        
        uint256 decimal = 10 ** 18;
        
        rate = feePayTokenList[token];
        if(rate > 0){
            tokenFee = mulDiv(amount, feePayTokenList[token], decimal);
            amountValid = amount.sub(tokenFee);
        }else{
            tokenFee = 0;
            amountValid = amount;
        }
    }
    
    // purchase order
    function purchaseOrder(uint256 orderID) public payable nonReentrant {
        require(orderID > 0, "order id cannot be 0");
        require(orderIdIsExisted(orderID) == true, "order is not existed");
        require(orderList[orderID].SoldStatus == 1, "order cannot sold");
        
        address _payTokenAddress = allowedPayTokens[orderList[orderID].PayTokenType];
        uint256 _payAmount = orderList[orderID].PayAmount;
        address _OrderOwner = orderList[orderID].OrderOwner;
        address _NFTToken = orderList[orderID].NFTToken;
        uint256 _NFTTokenID = orderList[orderID].NFTTokenID;
        
        // calculate arrival amount
        (uint256 tokenFee, uint256 amountValid, uint256 rate) = calculateArrivalAmount(_payAmount, _payTokenAddress);
            
        if( _payTokenAddress == HTTOKENADDRESS ){
            // HT
            require(msg.value == _payAmount, "pay amount is error");
        
            orderList[orderID].SoldStatus = 2;
            
            if((tokenFee > 0) && (rate > 0)){
                address payable _feeTo = address(uint160(feeTo));
                _feeTo.transfer(tokenFee);
            }
            
            address payable _OrderOwnerAddress = address(uint160(_OrderOwner));
            _OrderOwnerAddress.transfer(amountValid);
            
        }else{
            orderList[orderID].SoldStatus = 2;
        
            // other token
            if((tokenFee > 0) && (rate > 0)){
                IERC20(_payTokenAddress).safeTransferFrom(msg.sender, feeTo, tokenFee);
            }
            IERC20(_payTokenAddress).safeTransferFrom(msg.sender, _OrderOwner, amountValid);
        }

        IERC721(_NFTToken).safeTransferFrom(address(this), msg.sender, _NFTTokenID);
        
        emit PurchaseOrder(orderID);
    }

    // extract Fee(
    function extractFee() public nonReentrant onlyOwner{
        require(address(this).balance > 0, "balance cannot be 0");
        msg.sender.transfer(address(this).balance);
    }

    // extract token fee
    function extractTokenFee(address token) public nonReentrant onlyOwner{
        require(token != address(0), "token is zero address");
        require(payTokenIsAllowed(token) == true, "token is not allowed");
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "balance cannot be 0");
        
        IERC20(token).safeApprove(address(this), balance);
        IERC20(token).safeTransferFrom(address(this), msg.sender, balance);
    }

}