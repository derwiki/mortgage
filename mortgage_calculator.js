var PROPERTY_TAX_RATE = 0.015;
var home_value = 1000000.0;
var deposit = 500000;
var yearly_property_tax = home_value * PROPERTY_TAX_RATE;
var monthly_property_tax = yearly_property_tax / 12.0;
var monthly_property_tax_adjustment = monthly_property_tax * 0.36;
var principal = 500000.0;
var monthly_interest_rate = 0.03 / 12;
var total_payments = 360;
var num = principal * (monthly_interest_rate * Math.pow( 1 + monthly_interest_rate, total_payments));
var denom = Math.pow(1 + monthly_interest_rate, total_payments) - 1;
var monthly_mortgage_payment = num / denom;
var net_cost = monthly_mortgage_payment + monthly_property_tax;
console.log( 'monthly_mortgage_payment', monthly_mortgage_payment );
console.log( 'mortgage + property tax', net_cost );
console.log( "savings from property tax writeoff", monthly_property_tax_adjustment);
console.log( "adjusted cost", net_cost - monthly_property_tax_adjustment );
console.log( "monthly mortgage payment", monthly_mortgage_payment);

function calculateMonthlyPayments(target_monthly_payment, hoa) {
  var payments = [];
  running_principal = principal
  running_value = home_value

  for (var month = 0; month < 360; month++) {
    var amounts = {};
    amounts['month'] = month;
    amounts['interest'] = monthly_interest_rate * running_principal
    amounts['principal'] = monthly_mortgage_payment - amounts['interest']
    amounts['principal'] += (target_monthly_payment - monthly_mortgage_payment - hoa)
    running_principal -= amounts['principal']
    amounts['property_tax'] = monthly_property_tax
    amounts['hoa'] = hoa
    amounts['deductible'] = amounts['interest'] + monthly_property_tax
    amounts['deduction_savings'] = amounts['deductible'] * 0.36
    amounts['adjusted_monthly_payment'] = target_monthly_payment - amounts['deduction_savings']
    amounts['running_principal'] = running_principal
    amounts['running_value'] = (running_value *= 1.00583) // 1.07 / 12 months
    amounts['ownership'] = home_value - running_principal
    amounts['ownership_percent'] = amounts['ownership'] / home_value
    amounts['total_paid'] = month * target_monthly_payment + deposit
    // profit_rate = amounts['running_value'] / home_value
    // this still doesn't seem right..
    amounts['running_profit'] = (running_value - amounts['total_paid']) * amounts['ownership_percent']
    payments.push(amounts);

    if (month == 7 * 12) {
      console.log(" ** 7 years, $"+target_monthly_payment+"/month, "+amounts['running_value']+", HOA: "+hoa);
      console.log(amounts);
    }
    months_to_payoff_by_monthly_payment[Math.round(target_monthly_payment)] = month;
    if (running_principal < 0) { break; }
  }

  return payments;
};

hoas = [0, 300, 500, 800];
target_monthly_payments = [monthly_mortgage_payment + monthly_property_tax, 4000, 5000];

months_to_payoff_by_monthly_payment = {}
for (var i = 0; i < hoas.length; i++) {
  var hoa = hoas[i];

  for (var j = 0; j < target_monthly_payments.length; j++) {
    var target_monthly_payment = target_monthly_payments[j];
    var payments = calculateMonthlyPayments(target_monthly_payment, hoa);
    console.log('payments', payments);
  }
  console.log(months_to_payoff_by_monthly_payment);
}
