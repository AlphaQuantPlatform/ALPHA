pragma solidity ^0.4.17;
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AlphaToken.sol";

/**
 * @title AlphaTokenSale
 * @dev AlphaTokenSale is a base contract for managing a token AlphaTokenSale.
 * AlphaTokenSales have a start and end timestamps, where investors can make
 * token purchases and the AlphaTokenSale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract AlphaTokenSale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  AlphaToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  address public tokenAddr;

  mapping(address => bool) public whiteset;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function AlphaTokenSale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenAddr, address[] _whitelist) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));



    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    tokenAddr = _tokenAddr;
    for (uint i = 0; i < _whitelist.length; i++) {
      whiteset[_whitelist[i]] = true;
    }
    token = AlphaToken(tokenAddr);
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) onlyWhite public payable {
    //TODO: give back some eth when tokens is not enough
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.transferFrom(owner, beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if AlphaTokenSale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  function inWhiteList() internal view returns (bool) {
    return whiteset[msg.sender];
  }

  modifier onlyWhite() {
    require(inWhiteList());
    _;
  }
}
