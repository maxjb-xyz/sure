class UI::Account::Chart < ApplicationComponent
  attr_reader :account

  def initialize(account:, period: nil, view: nil)
    @account = account
    @period = period
    @view = view
  end

  def period
    @period ||= Period.last_30_days
  end

  # Current value of holdings that aren't cash equivalents (e.g. money market/sweep
  # funds, or a synthetic non-primary-currency cash holding) -- kept in sync with how
  # Balance::SyncCache#get_holdings_value splits cash vs. holdings for the balance
  # chart, so this header stat and the chart agree on what counts as "holdings".
  def holdings_value_money
    total = account.current_holdings.includes(:security).reject { |h| h.cash_equivalent? || h.security.cash? }.sum do |h|
      begin
        Money.new(h.amount, h.currency).exchange_to(account.currency, date: h.date).amount
      rescue Money::ConversionError
        h.amount
      end
    end

    Money.new(total, account.currency)
  end

  # Cash equivalents are excluded from holdings_value_money above, so deriving cash
  # from the total (rather than reading account.cash_balance_money directly) folds
  # their value back into "cash" here -- matching the chart's cash_balance view.
  def cash_balance_money
    account.balance_money - holdings_value_money
  end

  def view_balance_money
    case view
    when "balance"
      account.balance_money
    when "holdings_balance"
      holdings_value_money
    when "cash_balance"
      cash_balance_money
    end
  end

  def title
    case account.accountable_type
    when "Investment", "Crypto"
      case view
      when "balance"
        I18n.t("UI.account.chart.title.total_account_value")
      when "holdings_balance"
        I18n.t("UI.account.chart.title.holdings_value")
      when "cash_balance"
        I18n.t("UI.account.chart.title.cash_value")
      end
    when "Property"
      I18n.t("UI.account.chart.title.estimated_property_value")
    when "Vehicle"
      I18n.t("UI.account.chart.title.estimated_vehicle_value")
    when "CreditCard", "OtherLiability"
      I18n.t("UI.account.chart.title.debt_balance")
    when "Loan"
      I18n.t("UI.account.chart.title.remaining_principal_balance")
    else
      I18n.t("UI.account.chart.title.balance")
    end
  end

  def foreign_currency?
    account.currency != account.family.currency
  end

  def converted_balance_money
    return nil unless foreign_currency?

    begin
      account.balance_money.exchange_to(account.family.currency)
    rescue Money::ConversionError
      nil
    end
  end

  def view
    @view ||= "balance"
  end

  def series
    account.balance_series(period: period, view: view)
  end

  def trend
    series.trend
  end

  def comparison_label
    start_date = series.start_date
    return period.comparison_label if start_date.blank?

    if start_date > period.start_date
      I18n.t("UI.account.chart.vs_available_history")
    else
      period.comparison_label
    end
  end
end
