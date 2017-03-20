require 'byebug'
require 'csv'
require 'set'
require 'awesome_print'
require 'active_support/core_ext/integer/time' # for Numeric#months

class Mortgage
  TOTAL_PAYMENTS = 360
  HOME_VALUE_YEARLY_GROWTH_RATE = 0.04

  def initialize(home_value: , deposit: , hoa: , property_tax_rate: , target_monthly_payment: , first_month: )
    @home_value = home_value
    @deposit = deposit
    @hoa = hoa
    @property_tax_rate = property_tax_rate
    @monthly_property_tax = property_tax_rate / 12.0
    @target_monthly_payment = target_monthly_payment
    @first_month = first_month
  end

  def monthly_interest_rate(month)
    fail NotImplementedError
  end

  def monthly_mortgage_payment(month)
    rate = monthly_interest_rate(month)
    (@home_value - @deposit) * (rate * ( 1 + rate) ** TOTAL_PAYMENTS) / ((1 + rate) ** TOTAL_PAYMENTS - 1)
  end

  def miniumum_monthly_payment(month)
    monthly_mortgage_payment(month) + @monthly_property_tax + @hoa
  end

  def perform
    deductions = Hash.new(0)
    running_principal = @home_value - @deposit
    running_value = @home_value
    running_interest = 0
    running_payments = 0
    monthly_payments = Hash.new(0)

    TOTAL_PAYMENTS.times do |month|
      date = @first_month + month.months
      minimum_payment = miniumum_monthly_payment(month)
      monthly_payment = [minimum_payment, @target_monthly_payment].max
      monthly_payments[monthly_payment.to_i] += 1

      amounts = {}
      amounts[:month] = month
      amounts[:monthly_payment] = monthly_payment
      running_payments += monthly_payment

      amounts[:interest_rate] = monthly_interest_rate(month) * 12
      amounts[:interest] = monthly_interest_rate(month) * running_principal
      running_interest += amounts[:interest]
      amounts[:running_interest] = running_interest

      amounts[:principal] = monthly_payment - amounts[:interest] - @monthly_property_tax - @hoa
      running_principal -= amounts[:principal]
      amounts[:running_principal] = running_principal

      amounts[:deduction_savings] = (amounts[:interest] + @monthly_property_tax) * 0.36
      deductions[date.year] += amounts[:interest] + @monthly_property_tax
      amounts[:adjusted_monthly_payment] = monthly_payment - (amounts[:interest] + @monthly_property_tax) * 0.36

      running_value *= (1 + (HOME_VALUE_YEARLY_GROWTH_RATE / 12))
      amounts[:running_value] = running_value
      amounts[:ownership_percent] = 100.0 * (@home_value - running_principal) / @home_value

      if running_principal <= 0
        summary = {
          target_monthly_payment: @target_monthly_payment,
          loan: self.class.name,
          years: (month / 12.0).round(1),
          loan_amount: (@home_value - @deposit).round,
          interest: running_interest.round,
          payments: running_payments.round,
          paid: (@deposit + running_payments).round,
          value: running_value.round,
          percent_interest: (100.0 * running_interest / running_payments).round(1)
        }
        summary[:multiplier] = (summary[:payments] / summary[:loan_amount].to_f).round(2)
        summary[:projected_profit] = summary[:value] - summary[:paid]
        summary[:deductions] = Hash[deductions.map {|k,v|[k,v.to_i]}]
        summary[:monthly_payments] = monthly_payments

        # summary.except(:deductions, :monthly_payments).keys
        return summary
      end
    end
  end
end

class FiveFiveMortgage < Mortgage
  def monthly_interest_rate(month)
    if month / 12 < 5
      0.04199 / 12
    elsif month / 12 < 10
      0.06199 / 12
    elsif month / 12 < 15
      0.08199 / 12
    else # lifetime cap of 5% over the initial rate
      0.10199 / 12
    end
  end
end

class AdjustableRateMortgage < Mortgage
  LIBOR = 0.0176
  MARGIN = 0.035

  def intro_rate
    fail NotImplementedError
  end

  def cap_rate
    self.intro_rate + 0.05
  end

  def monthly_interest_rate(month)
    if month / 12 < self.change_year
      intro_rate / 12
    else
      #(LIBOR + MARGIN) / 12
      self.cap_rate / 12
    end
  end
end

class ThreeOneMortgage < AdjustableRateMortgage
  def intro_rate
    0.04044
  end

  def change_year
    3
  end
end

class FiveOneMortgage < AdjustableRateMortgage
  def intro_rate
    0.04151
  end

  def change_year
    5
  end
end

class SevenOneMortgage < AdjustableRateMortgage
  def intro_rate
    0.04275
  end

  def change_year
    7
  end
end

class ThirtyYearMortgage < Mortgage
  def monthly_interest_rate(_)
    0.0425 / 12
  end
end

class MortageComparer
  CLASSES = [ThirtyYearMortgage, FiveFiveMortgage, SevenOneMortgage]
  def self.perform
    summary = {}
    CLASSES.each do |klass|
      klass_key = klass.to_s.split(' ').first
      (4000..10000).step(500).each do |target_monthly_payment|
        params = {
          home_value: 1_250_000,
          deposit: 641_000,
          hoa: 350,
          property_tax_rate: 0.01179,
          target_monthly_payment: target_monthly_payment,
          first_month: Date.new(2017, 5, 1)
        }
        summary[klass_key] ||= {}
        summary[klass_key][target_monthly_payment] = klass.new(params).perform
      end
    end
    summary
  end
end

ap MortageComparer.perform
