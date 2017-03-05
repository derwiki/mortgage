require 'awesome_print'

PROPERTY_TAX_RATE = 0.015
HOME_VALUE = 1_100_000.0
HOA = 250
deposit = 500_000 + 0.03 * HOME_VALUE
yearly_property_tax = HOME_VALUE * PROPERTY_TAX_RATE
MONTHLY_PROPERTY_TAX = yearly_property_tax / 12.0
MONTHLY_PROPERTY_TAX_ADJUSTMENT = MONTHLY_PROPERTY_TAX * 0.36

PRINCIPAL = HOME_VALUE - deposit
puts "total amount of loan: #{PRINCIPAL}"

def monthly_interest_rate(month)
  if month / 12 < 5
    0.04125 / 12
  elsif month / 12 < 10
    0.06125 / 12
  elsif month / 12 < 15
    0.08125 / 12
  else # lifetime cap of 5% over the initial rate
    0.09125 / 12
  end
end

TOTAL_PAYMENTS = 360

def monthly_mortgage_payment(month)
  rate = monthly_interest_rate(month)
  PRINCIPAL * (rate * ( 1 + rate) ** TOTAL_PAYMENTS) / ((1 + rate) ** TOTAL_PAYMENTS - 1)
end

def miniumum_monthly_payment(month)
  monthly_mortgage_payment(month) + MONTHLY_PROPERTY_TAX + HOA
end

def maybe_month_divider(month)
  return unless [5, 10, 15, 20, 25, 30].include?(month % 12 == 0 ? month / 12 : nil)
  puts "\n#{ ?- * 25 } #{month / 12} #{ ?- * 25 }\n"
end

summary = {}
[0, 5000, 5250, 5500, 5750, 6000, 6500].each do |target_monthly_payment|
  running_principal = PRINCIPAL
  running_interest = 0
  running_value = HOME_VALUE
  running_payments = 0
  running_deductions = 0
  (30 * 12).times do |month|
    maybe_month_divider(month)

    minimum_payment = miniumum_monthly_payment(month)
    monthly_payment = [minimum_payment, target_monthly_payment].max

    amounts = {}
    amounts[:month] = month
    amounts[:monthly_payment] = monthly_payment
    running_payments += monthly_payment

    amounts[:interest_rate] = monthly_interest_rate(month) * 12
    amounts[:interest] = monthly_interest_rate(month) * running_principal
    running_interest += amounts[:interest]
    amounts[:running_interest] = running_interest

    amounts[:principal] = monthly_payment - amounts[:interest] - MONTHLY_PROPERTY_TAX - HOA
    running_principal -= amounts[:principal]
    amounts[:running_principal] = running_principal

    #amounts[:property_tax] = MONTHLY_PROPERTY_TAX
    #amounts[:hoa] = HOA

    #amounts[:deductible] = amounts[:interest] + MONTHLY_PROPERTY_TAX
    amounts[:deduction_savings] = (amounts[:interest] + MONTHLY_PROPERTY_TAX) * 0.36
    running_deductions += amounts[:deduction_savings]
    #amounts[:adjusted_monthly_payment] = monthly_payment - amounts[:deduction_savings]
    amounts[:adjusted_monthly_payment] = monthly_payment - (amounts[:interest] + MONTHLY_PROPERTY_TAX) * 0.36

    running_value *= (1 + (0.03 / 12))
    amounts[:running_value] = running_value
    #amounts[:ownership] = HOME_VALUE - running_principal
    amounts[:ownership_percent] = 100.0 * (HOME_VALUE - running_principal) / HOME_VALUE
    #amounts[:total_paid] = month * monthly_payment + deposit

    # puts Hash[amounts.map {|k,v| [k,v.round(3)]}]

    if running_principal <= 0
      key = target_monthly_payment.round
      summary[key] = {
        years: (month / 12.0).round(1),
        interest: running_interest.round,
        payments: (deposit + running_payments).round,
        deduction_savings: running_deductions.round,
        adjusted_payments: (deposit + running_payments - running_deductions).round,
        value: running_value.round,
        percent_interest: (100.0 * running_interest / running_payments).round(1)
      }
      summary[key][:projected_profit] = summary[key][:value] - summary[key][:adjusted_payments]
      break
    end
  end
end
ap(summary)
