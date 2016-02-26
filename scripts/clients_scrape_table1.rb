require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'fileutils'

$masterlist = []

# Change the working directory
Dir.chdir("C:/Data/Lobbyists/")

# Set the year
puts "Specify the year, please."
$year = gets
$year = $year.chomp

# Capture the name of each HTML file in the directory
$htmlfiles = Dir["htmlfiles/#{$year}/*.html"]

# Isolate the ID number from each file name
$htmlfiles.map! {|filename|
  @fullname = filename
  @id = filename.gsub("htmlfiles/#{$year}/", "")
  @id.gsub!(".html", "")
  filename = [@id, @fullname]
}

def tablescrape(id,htmlfile)
  @id = id
  @htmlfile = htmlfile
  @htmlpage = Nokogiri::HTML(open("#{@htmlfile}"))
  
  # Identifying information
  @name = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegistrantName']").text
  @year = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblYear']").text
  @type = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegType']").text
  @address = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegistrantAddress']").text
  
  if @type == "Client"
    # Lobbyist info
    @totalsalarypaid = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_lblTotalExpense']").text

    # Expenses
    @expenses = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblTotalExpense']").text
    @expense0_name = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblExpenseName_0']").text
    @expense1_name = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblExpenseName_1']").text
    @expense2_name = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblExpenseName_2']").text
    @expense0_amount = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblAmount_0']").text
    @expense1_amount = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblAmount_1']").text
    @expense2_amount = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptExpense_lblAmount_2']").text  

    if @expense0_name == "Operating Expenses"
      @op_expenses = @expense0_amount
    elsif @expense1_name == "Operating Expenses"
      @op_expenses = @expense1_amount
    elsif @expense2_name == "Operating Expenses"
      @op_expenses = @expense2_amount
    else @op_expenses = nil
    end

    if @expense0_name == "Meal, Entertainment, and Transportation Expenses"
      @mealstravel_expenses = @expense0_amount
    elsif @expense1_name == "Meal, Entertainment, and Transportation Expenses"
      @mealstravel_expenses = @expense1_amount
    elsif @expense2_name == "Meal, Entertainment, and Transportation Expenses"
      @mealstravel_expenses = @expense2_amount
    else @mealstravel_expenses = nil
    end

    if @expense0_name == "Additional Expenses"
      @addl_expenses = @expense0_amount
    elsif @expense1_name == "Additional Expenses"
      @addl_expenses = @expense1_amount
    elsif @expense2_name == "Additional Expenses"
      @addl_expenses = @expense2_amount
    else @addl_expenses = nil
    end

    # Clean up @totalsalarypaid, @expenses by removing commas and dollar signs
    @totalsalarypaid.gsub!(",", "")
    @totalsalarypaid.gsub!("$", "")
    @expenses.gsub!(",", "")
    @expenses.gsub!("$", "")
    @op_expenses.gsub!(",", "") unless @op_expenses == nil
    @op_expenses.gsub!("$", "") unless @op_expenses == nil
    @mealstravel_expenses.gsub!(",", "") unless @mealstravel_expenses == nil
    @mealstravel_expenses.gsub!("$", "") unless @mealstravel_expenses == nil
    @addl_expenses.gsub!(",", "") unless @addl_expenses == nil
    @addl_expenses.gsub!("$", "") unless @addl_expenses == nil

    # Create an array that combines all of the variables from the HTML file
    @subarray = [@id, @name, @year, @type, @address, @totalsalarypaid, @expenses, @op_expenses, @mealstravel_expenses, @addl_expenses]
    $masterlist << @subarray
    puts "Added #{@id} to the list."
  end
end

# Scrape each HTML file
$htmlfiles.each {|array| tablescrape(array[0],array[1])}

# Insert column headings into the first row of the $masterlist
$masterlist.insert(0, ["id", "name", "year", "type", "address", "total_salary_paid", "expenses", "op_expenses", "mealstravel_expenses", "addl_expenses"])

# Save the values to a CSV file
CSV.open("data/clients#{$year}_table1.csv","w") do |csv|
$masterlist.each { |row|
  csv << row
}
end