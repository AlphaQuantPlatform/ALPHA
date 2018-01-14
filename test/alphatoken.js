var AlphaToken = artifacts.require("./AlphaToken.sol");

contract('AlphaToken', function(accounts) {
  it("should put totalSupply AlphaToken in the first account", function() {
    return AlphaToken.deployed().then(function(instance) {
      return Promise.all([instance.balanceOf.call(accounts[0]), instance.totalSupply()]);
    }).then(function(balance) {
      assert.equal(balance[0].valueOf(), balance[1].valueOf(), "totalSupply wasn't in the first account");
    });
  });

  it("should send coin correctly", function() {
    var alpha;

    //    Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return AlphaToken.deployed().then(function(instance) {
      alpha = instance;
      return alpha.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return alpha.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return alpha.transfer(account_two, amount, {from: account_one});
    }).then(function() {
      return alpha.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return alpha.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });
});
