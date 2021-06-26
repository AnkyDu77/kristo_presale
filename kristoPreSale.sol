pragma solidity ^0.6.2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/math/SafeMath.sol";


contract kristoPreSale is ERC20, Ownable {

    using SafeMath for uint256;

    address payable workingWallet = 0x12bc5a1F61D1D40EB81D4ea086DCE4753D4cd8c9; //0x57169Efe0245596DebA942621f1AFe51fd11034C
    address USDT = 0x8a0E28e6731beBa91605991a3e7360338a5a02b2; //0x6EE856Ae55B6E1A249f04cd3b947141bc146273c

    uint256 private lockupStart = now;
    uint256 private lockupEnd = lockupStart.add(216000); // 39312000 Lockup period ends in a year and a quoter
    uint256 private presaleEnd = lockupStart.add(172800); // 5241600 Presale ends in a two months


    uint256 private HARD_SUPPLY = 48300000000000; //8000000000000000000000

    uint256 private WORKING_INVEST_SHARE = 25; // It is 25% with 0-digits accuracy (to get actual percentge div by 100)
    uint256 private MULTIPLIER = 12;
    uint256 private PRICE_ACCURACY = 1000000000;//000000000

    constructor (uint8 decimals) public ERC20('KristoZeroInvestRound', 'KRSTzr')  {
            _setupDecimals(decimals);
    }


    // Investment function
    function getTokens(uint256 tokenToSendAmount) public {

        // Require to meet proper time period
        require(now < presaleEnd, "KRISTO_PRESALE_ERROR: Presale ended. Sorry. You can buy pool tokens available on the smart contract by buyAvailablePoolTokens(uint256 tokenToSendAmount) function");
        require(checkPoolTokensLimit(tokenToSendAmount) == true, "KRISTO_PRESALE_ERROR: Sorry, pool token mint exceeds presale limit. Check alailable supply by checkSupplyLeft() func");

        // Get user's tokenToSend to the SmartContract
        ERC20(USDT).transferFrom(msg.sender, address(this), tokenToSendAmount);

        // Define how much will we get
        uint256 workingInvestmentsToGet = (tokenToSendAmount.mul(WORKING_INVEST_SHARE)).div(100);

        // Transfer working investments
        ERC20(USDT).transfer(workingWallet, workingInvestmentsToGet);

        // Mint and send to user his/her poolTokens
        ERC20._mint(msg.sender, tokenToSendAmount.mul(MULTIPLIER));
    }


    // Withdraw USDT and burn poolTokens
    function withdraw(uint256 poolTokensSending) public {

        // Require to meet proper time period
        require(lockupEnd < now, "KRISTO_PRESALE_ERROR: We are still in a lock up period. Please, come back later");

        // Define user's pool share
        uint256 usdtToWithdraw = poolTokensSending.mul(getAvailablePoolTokensPrice());
        // Encrese accuracy
        usdtToWithdraw = usdtToWithdraw.div(PRICE_ACCURACY);

        // Get poolTokens from user
        ERC20(address(this)).transferFrom(msg.sender, address(this), poolTokensSending);
        // Transfer USDT to user
        ERC20(USDT).transfer(msg.sender, usdtToWithdraw);

    }


    function buyAvailablePoolTokens(uint256 tokenToSendAmount) public {
        // Require to meet proper time period
        require(lockupEnd < now, "KRISTO_PRESALE_ERROR: We are still in a lock up period. Please, come back later");

        uint256 poolTokenPrice = getAvailablePoolTokensPrice();
        uint256 poolTokensVolToBuy = tokenToSendAmount.div(poolTokenPrice);

        //Get Accurate Amount
        poolTokensVolToBuy = poolTokensVolToBuy.mul(PRICE_ACCURACY);

        require(poolTokensVolToBuy <= ERC20(address(this)).balanceOf(address(this)), "KRISTO_PRESALE_ERROR: There is not enough pool tokens avaliable. Try to buy less");
        ERC20(USDT).transferFrom(msg.sender, address(this), tokenToSendAmount);
        
        ERC20(address(this)).transfer(msg.sender, poolTokensVolToBuy);

    }


    function getAvailablePoolTokensPrice() public view returns (uint256) {

        uint256 totalUSDTpoolBalance = ERC20(USDT).balanceOf(address(this));
        uint256 totalPoolTokenSupply = ERC20(address(this)).totalSupply();
        uint256 avaliableTokes = getAvailablePoolTokensVolume();
        // Clinch pool token price
        uint256 poolTokensFreeFlow = totalPoolTokenSupply.sub(avaliableTokes);

        totalUSDTpoolBalance = totalUSDTpoolBalance.mul(PRICE_ACCURACY); // Encrease accuracy
        uint256 poolTokenPrice = totalUSDTpoolBalance.div(poolTokensFreeFlow);
        return poolTokenPrice;

    }


    function setNewWorkingWallet(address payable newWorkingWallet) public onlyOwner {
        workingWallet = newWorkingWallet;
    }


    function checkSupplyLeft() public view returns (uint256) {

        uint256 supplyLeft = HARD_SUPPLY.sub(ERC20(address(this)).totalSupply());
        return supplyLeft;
    }


    function checkPoolTokensLimit(uint256 tokenToSendAmount) private view returns (bool) {

        if ((tokenToSendAmount.mul(MULTIPLIER)).add(ERC20(address(this)).totalSupply()) <= HARD_SUPPLY) {
            return true;
        } else {
            return false;
        }
    }


    function getPreSaleEnd() public view returns (uint256) {

        return presaleEnd;
    }


    function getLockUpEnd() public view returns (uint256) {

        return lockupEnd;
    }


    function getPriceAccuracy() public view returns (uint256) {

        return PRICE_ACCURACY;
    }
    
    function getMultiplier() public view returns (uint256) {
        
        return MULTIPLIER;
    }


    function getAvailablePoolTokensVolume() public view returns (uint256) {

        uint256 tokensOnContract = ERC20(address(this)).balanceOf(address(this));
        return tokensOnContract;
    }


    fallback () external payable {

        payable(msg.sender).transfer(msg.value);

    }


}
