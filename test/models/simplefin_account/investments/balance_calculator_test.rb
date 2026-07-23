require "test_helper"

class SimplefinAccount::Investments::BalanceCalculatorTest < ActiveSupport::TestCase
  test "cash_equivalent? matches a known money market ticker" do
    assert SimplefinAccount::Investments::BalanceCalculator.cash_equivalent?(symbol: "SPAXX", description: "Fidelity Government Money Market Fund")
    assert SimplefinAccount::Investments::BalanceCalculator.cash_equivalent?(symbol: "spaxx", description: "")
  end

  test "cash_equivalent? matches a description pattern when ticker is unknown" do
    assert SimplefinAccount::Investments::BalanceCalculator.cash_equivalent?(symbol: "XYZMM", description: "XYZ Money Market Settlement Fund")
  end

  test "cash_equivalent? is false for a regular stock" do
    assert_not SimplefinAccount::Investments::BalanceCalculator.cash_equivalent?(symbol: "AAPL", description: "Apple Inc")
  end
end
