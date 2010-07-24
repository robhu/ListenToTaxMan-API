# PLEASE NOTE: This code is provided / used at your own risk, and is not developed by the same person who writes listentotaxman.com
#
# If this is of any use to you you should go and make a donation via Paypal on the site listentotaxman.com

require 'rubygems'
require 'mechanize'
require 'ostruct'

def get_tax_figures(params = {})
  throw "Salary must be specified" unless params[:salary]
  
  agent = Mechanize.new
  page = agent.get('http://listentotaxman.com/index.php')
  form = page.forms[0]
  form.ingr = params[:salary]
  
  # set year like :year => 2008 (for 2008/2009)
  # age is stupid, 0 => 'under 65', 1 => '65-74', 2 => 'over 75', 3 => 'female 60-65'
  {:year => :yr, :age => :age}.each do |option, name|
    params[option] ? form.send("#{name}=", params[option]) : params[option] = form.send(name).to_i
  end
  
  {:is_married => 'married', :exclude_ni => 'exNI', :is_blind => 'blind', :include_student_loan => 'student'}.each do |option, name|
    checkbox = form.checkboxes.find{|cb| cb.name==name}
    params[option] ? checkbox.checked = true : params[option] = checkbox.checked
  end
    
  page = form.submit
  
  result = OpenStruct.new
  result.gross_pay = page.body.match(/Gross Pay.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.tax_free_allowances = page.body.match(/Tax free Allowances.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.total_taxable = page.body.match(/Total taxable.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.tax_due = page.body.match(/Tax due.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  
  result.tax_bands = {}
  [10, 20, 22, 40, 50].each do |tax_rate|
    regex = /#{tax_rate}% tax rate.*?&pound;(.*?)</m
    result.tax_bands[tax_rate] = page.body.match(regex)[1].gsub(',', '').to_f if page.body.match(regex)
  end
  
  result.ni = page.body.match(/National Insurance.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.total_deductions = page.body.match(/Total Deductions.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.tax_bands['student_loan'] = page.body.match(/Student Loan<\/td>.*?&pound;(.*?)</m)[1].gsub(',', '').to_f if page.body.match(/Student Loan<\/td>.*?&pound;(.*?)</m)
  result.net_wage = page.body.match(/Net Wage.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.employers_ni = page.body.match(/Employers NI.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  result.ni = page.body.match(/National Insurance.*?&pound;(.*?)</m)[1].gsub(',', '').to_f
  
  result.options = params
  
  return result
end

puts get_tax_figures :salary => 24_000, :year => 2007, :exclude_ni => true, :is_married => true
#<OpenStruct total_deductions=3862.9, tax_due=3862.9, net_wage=20137.1, tax_bands={22=>3639.9, 40=>0.0, 10=>223.0}, employers_ni=0.0, gross_pay=24000.0, tax_free_allowances=5225.0, options={:include_student_loan=>false, :age=>0, :is_married=>true, :year=>2007, :salary=>24000, :exclude_ni=>true, :is_blind=>false}, ni=0.0, total_taxable=18775.0>

puts get_tax_figures :salary => 24_000, :year => 2007, :exclude_ni => true, :is_blind => true
#<OpenStruct total_deductions=3482.3, tax_due=3482.3, net_wage=20517.7, tax_bands={22=>3259.3, 40=>0.0, 10=>223.0}, employers_ni=0.0, gross_pay=24000.0, tax_free_allowances=6955.0, options={:include_student_loan=>false, :age=>0, :is_married=>false, :year=>2007, :salary=>24000, :exclude_ni=>true, :is_blind=>true}, ni=0.0, total_taxable=17045.0>

puts get_tax_figures :salary => 24_000, :year => 2007, :exclude_ni => true, :include_student_loan => true
#<OpenStruct total_deductions=4672.9, tax_due=3862.9, net_wage=19327.1, tax_bands={"student_loan"=>810.0, 22=>3639.9, 40=>0.0, 10=>223.0}, employers_ni=0.0, gross_pay=24000.0, tax_free_allowances=5225.0, options={:include_student_loan=>true, :age=>0, :is_married=>false, :year=>2007, :salary=>24000, :exclude_ni=>true, :is_blind=>false}, ni=0.0, total_taxable=18775.0>