pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract GLMNFT is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 private constant maxSupply = 1111;
    uint256[maxSupply] profitsList;

    event AllotProfits(address token, uint256 amount);
    event AllotProfitsByNumber(address token, uint256 amount, uint256 start, uint256 num);
    event ClaimProfits(address token);
  
    constructor() public ERC721("NEXTYPE GENESIS LAUNCH MEMORIAL", "NEXTYPE GLM") {
 
    }
  
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function mintItem(address recipient) public onlyOwner returns (uint256) {
        require(recipient != address(0), "recipient is zero address");
        require(totalSupply() + 1 <= maxSupply, "Total issuance exceeds the limit!");

        uint256 mintIndex = totalSupply() + 1;
        _safeMint(recipient, mintIndex);
        
        return mintIndex;
    }
    
    function mintItems(address recipient, uint256 numberOfTokens) external onlyOwner {
        require(recipient != address(0), "recipient is zero address");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Total issuance exceeds the limit!");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(recipient, mintIndex);
        }
    }

    function mintMulti(address[] memory recipient) public onlyOwner {
        require(recipient.length > 0, "Receiver is empty");
        require(totalSupply().add(recipient.length) <= maxSupply, "Total issuance exceeds the limit!");

        uint256 len = recipient.length;

        for(uint256 i = 0; i < len; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(recipient[i], mintIndex);
        }
    }

    function getAllOwner() external view returns(address[] memory ) {
        uint256 tmpTotalSupply = totalSupply();

        if (tmpTotalSupply <= 0) {
            // Return an empty array
            return new address[](0);
        } else {
            address[] memory result = new address[](tmpTotalSupply);
            uint256 index;
            for (index = 0; index < tmpTotalSupply; index++) {
                result[index] = ownerOf(index+1);
            }
            return result;
        }
    }


    function allotProfits(address token, uint256 amount) external onlyOwner nonReentrant {
        require(token != address(0), "token is zero address");
        require(amount > 0, "amount cannot be 0");
        uint256 tmpTotalSupply = totalSupply();
        require(tmpTotalSupply > 0, "totalSupply cannot be 0");

        uint256 tmpProfits = amount.div(tmpTotalSupply);

        uint256 index;
        for (index = 0; index < tmpTotalSupply; index++) {
            profitsList[index] = profitsList[index].add(tmpProfits);
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit AllotProfits(token, amount);
    }

    function allotProfitsByNumber(address token, uint256 amount, uint256 start, uint256 num) external onlyOwner nonReentrant {
        require(token != address(0), "token is zero address");
        require(amount > 0, "amount cannot be 0");
        require(num > 0, "num cannot be 0");
        uint256 tmpTotalSupply = totalSupply();
        require(tmpTotalSupply > 0, "totalSupply cannot be 0");
        require(start + num <= tmpTotalSupply, "num cannot gt tmpTotalSupply");

        uint256 tmpProfits = amount.div(num);

        uint256 index;
        for (index = start; index < start + num; index++) {
            profitsList[index] = profitsList[index].add(tmpProfits);
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit AllotProfitsByNumber(token, amount, start, num);
    }

    function claimProfits(address token) external nonReentrant {
        require(token != address(0), "token is zero address");

        uint256[] memory myTokens = tokensOfOwner(msg.sender);
        require(myTokens.length > 0, "mine token is empty");

        uint256 index;
        uint256 myProfits;

        for (index = 0; index < myTokens.length; index++) {
            if(myTokens[index] <= profitsList.length){
                myProfits = myProfits.add(profitsList[myTokens[index] - 1 ]);
            }
        }

        require(myProfits > 0, "my profits is zero");
        require(IERC20(token).balanceOf(address(this)) > myProfits, "Address: insufficient balance for call");

        for (index = 0; index < myTokens.length; index++) {
            if(myTokens[index] <= profitsList.length){
                profitsList[myTokens[index] - 1 ] = 0;
            }
        }

        IERC20(token).transfer(msg.sender, myProfits);

        emit ClaimProfits(token);
    }


    function getProfits(address token) external view returns(uint256) {
        require(token != address(0), "token is zero address");
        
        uint256[] memory myTokens = tokensOfOwner(token);
        if(myTokens.length <= 0){
            return 0;
        }

        uint256 index;
        uint256 myProfits;

        for (index = 0; index < myTokens.length; index++) {
            myProfits = myProfits.add(profitsList[myTokens[index] - 1 ]);
        }

        return myProfits;
        
    }

    function getProfitsFromTokenId(uint256 tokenId) public view returns (uint256){
        return profitsList[tokenId-1];
    }
    
    function getProfitsList() public view returns (uint256[] memory){
        uint256[] memory tmp = new uint256[](profitsList.length);
        uint256 index;
        
        for (index = 0; index < profitsList.length; index++) {
             tmp[index] = profitsList[index];
        }
        return tmp;
    }
}



