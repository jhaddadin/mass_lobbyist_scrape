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
  @counter = 0
  
  # Identifying information
  @name = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegistrantName']").text
  @year = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblYear']").text
  @type = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegType']").text
  
  if @type == "Lobbyist"
    # Count the number of clients the lobbyist has
    @clientsarray = []
    @clientsdiv = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_pnlClientInfo']/table/tr/td/a[@class='BlueLinks']")
    @clientsdiv.each {|client|
      @clientsarray << client.text
      }
    @counter = @clientsarray.count

    # Scrape each client from the div until @scrapecount matches @counter
    @scrapecount = 0

    until @scrapecount == @counter
      @subarray = []

      @clientname = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptClient_hlnkClientInformation_#{@scrapecount}']").text
      @clienturl = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptClient_hlnkClientInformation_#{@scrapecount}']/@href").text
      @clientrefid = @clienturl.gsub("Summary.aspx?PeriodId=2015&RefId=", "")
      @clientamount = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptClient_lblAmount_#{@scrapecount}']").text
      @clientemployed = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptClient_RptClientEmploymentInfo_#{@scrapecount}_lblEmploymentDate_0']").text
      @clientterminated = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptClient_RptClientEmploymentInfo_#{@scrapecount}_lblTerminationDate_0']").text
      @clientdetails = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptClient_RptClientEmploymentInfo_#{@scrapecount}_lblPurposeOfEmp_0']").text

      # Clean up payments by removing commas and dollar signs
      @clientamount.gsub!(",", "")
      @clientamount.gsub!("$", "")

      @subarray = [@id, @name, @year, @clientrefid, @clientname, @clientamount, @clientemployed, @clientterminated, @clientdetails]
      $masterlist << @subarray
      puts "Added #{@id} to the list."
      @scrapecount = @scrapecount + 1
    end
  end
end

# Scrape each HTML file
$htmlfiles.each {|array| tablescrape(array[0],array[1])}

# Insert column headings into the first row of the $masterlist
$masterlist.insert(0, ["id", "name", "year", "clientrefid", "clientname", "clientamount", "clientemployed", "clientterminated", "clientdetails"])

# Save the values to a CSV file
CSV.open("data/lobbyists#{$year}_clients.csv","w") do |csv|
$masterlist.each { |row|
  csv << row
}
end