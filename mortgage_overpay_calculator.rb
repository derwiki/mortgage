PROPERTY_TAX_RATE = 0.015
home_value = 1_000_000.0
deposit = 500_000
#loan_amount = home_value - deposit
yearly_property_tax = home_value * PROPERTY_TAX_RATE
monthly_property_tax = yearly_property_tax / 12.0
monthly_property_tax_adjustment = monthly_property_tax * 0.36

principal = 500_000.0
monthly_interest_rate = 0.03 / 12
total_payments = 360
monthly_mortgage_payment = principal * (monthly_interest_rate * ( 1 + monthly_interest_rate) ** total_payments) /
  ((1 + monthly_interest_rate) ** total_payments - 1)
puts monthly_mortgage_payment
puts monthly_mortgage_payment + monthly_property_tax
puts "savings from property tax writeoff: #{monthly_property_tax_adjustment}"
puts monthly_mortgage_payment + monthly_property_tax - monthly_property_tax_adjustment
puts "monthly mortgage payment: #{monthly_mortgage_payment.round}"

months_to_payoff_by_monthly_payment = {}
[0, 300, 500, 800].each do |hoa|
# [monthly_mortgage_payment, 3500, 4000, 4500, 5000].each do |target_monthly_payment|
  [4000].each do |target_monthly_payment|
    running_principal = principal
    running_value = home_value
    (30 * 12).times do |month|
      amounts = {}
      amounts[:interest] = monthly_interest_rate * running_principal
      amounts[:principal] = monthly_mortgage_payment - amounts[:interest]
      amounts[:principal] += (target_monthly_payment - monthly_mortgage_payment - hoa)
      running_principal -= amounts[:principal]
      amounts[:property_tax] = monthly_property_tax
      amounts[:hoa] = hoa
      amounts[:deductible] = amounts[:interest] + monthly_property_tax
      amounts[:deduction_savings] = amounts[:deductible] * 0.36
      amounts[:adjusted_monthly_payment] = target_monthly_payment - amounts[:deduction_savings]
      amounts[:running_principal] = running_principal
      amounts[:running_value] = (running_value *= 1.00583) # 1.07 / 12 months
      amounts[:ownership] = home_value - running_principal
      amounts[:ownership_percent] = amounts[:ownership] / home_value
      amounts[:total_paid] = month * target_monthly_payment + deposit
      # profit_rate = amounts[:running_value] / home_value
      # this still doesn't seem right..
      amounts[:running_profit] = (running_value - amounts[:total_paid]) * amounts[:ownership_percent]

      #puts Hash[amounts.map {|k,v| [k,v.to_i]}]
      if month == 7 * 12
        puts " ** 7 years, $#{target_monthly_payment.round(2)}/month, #{amounts.delete(:running_value).round}, HOA: #{hoa.round}"
        puts Hash[amounts.map {|k,v| [k,v.round(2)]}]
        puts
      end
      months_to_payoff_by_monthly_payment[target_monthly_payment.round] = month
      break if running_principal < 0
    end
  end
end
puts months_to_payoff_by_monthly_payment
