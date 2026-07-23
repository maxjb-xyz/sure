require "test_helper"

class UI::Account::ChartTest < ViewComponent::TestCase
  setup do
    @family = families(:dylan_family)
    @account = @family.accounts.create!(
      name: "Test Investment",
      balance: 6500,
      cash_balance: 1000,
      currency: "USD",
      accountable: Investment.new
    )

    stock = Security.create!(ticker: "TST", name: "Test Co")
    money_market = Security.create!(ticker: "SPAXX", name: "Money Market Fund")

    @account.holdings.create!(security: stock, date: Date.current, qty: 15, price: 100, amount: 1500, currency: "USD")
    @account.holdings.create!(security: money_market, date: Date.current, qty: 4000, price: 1, amount: 4000, currency: "USD", cash_equivalent: true)
  end

  test "holdings_value_money excludes cash-equivalent holdings" do
    component = UI::Account::Chart.new(account: @account, view: "holdings_balance")

    assert_equal Money.new(1500, "USD"), component.holdings_value_money
  end

  test "cash_balance_money folds cash-equivalent holding value back into cash" do
    component = UI::Account::Chart.new(account: @account, view: "cash_balance")

    # balance (6500) - holdings excluding SPAXX (1500) = 5000, i.e. the raw
    # cash_balance (1000) plus SPAXX's value (4000) -- not account.cash_balance_money (1000).
    assert_equal Money.new(5000, "USD"), component.cash_balance_money
    assert_equal Money.new(5000, "USD"), component.view_balance_money
  end

  test "view_balance_money for the balance view is unaffected" do
    component = UI::Account::Chart.new(account: @account, view: "balance")

    assert_equal Money.new(6500, "USD"), component.view_balance_money
  end
end
