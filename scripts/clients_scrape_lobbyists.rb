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
  
  if @type == "Client"
    # Count the number of lobbyists the client employs
    @lobbyistarray = []
    @lobbyistdiv = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_pnlLobbyistInfo']/table/tr/td/a[@class='BlueLinks']")
    @lobbyistdiv.each {|lobbyist|
      @lobbyistarray << lobbyist.text
      }
    @counter = @lobbyistarray.count

    # Scrape each lobbyist from the div until @scrapecount matches @counter
    @scrapecount = 0

    until @scrapecount == @counter
      @subarray = []

      @lobbyistname = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_hlnkClientInformation_#{@scrapecount}']").text
      @lobbyisturl = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_hlnkClientInformation_#{@scrapecount}']/@href").text
      @lobbyistrefid = @lobbyisturl.gsub("Summary.aspx?PeriodId=2015&RefId=", "")
      @lobbyistamount = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_lblAmount_#{@scrapecount}']").text
      @lobbyistemployed = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_RptLobbyistEmploymentInfo_#{@scrapecount}_lblEmploymentDate_0']").text
      @lobbyistterminated = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_RptLobbyistEmploymentInfo_#{@scrapecount}_lblTerminationDate_0']").text
      @lobbyistdetails = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptLobbyistInfo_RptLobbyistEmploymentInfo_#{@scrapecount}_lblPurposeOfEmp_0']").text

      # Clean up @totalsalarypaid, @expenses by removing commas and dollar signs
      @lobbyistamount.gsub!(",", "")
      @lobbyistamount.gsub!("$", "")

      @subarray = [@id, @name, @year, @lobbyistrefid, @lobbyistname, @lobbyistamount, @lobbyistemployed, @lobbyistterminated, @lobbyistdetails]
      $masterlist << @subarray
      puts "Added #{@id} to the list."
      @scrapecount = @scrapecount + 1
    end
  end
end

# Scrape each HTML file
$htmlfiles.each {|array| tablescrape(array[0],array[1])}

# Insert column headings into the first row of the $masterlist
$masterlist.insert(0, ["id", "name", "year", "lobbyistrefid", "lobbyistname", "lobbyistamount", "lobbyistemployed", "lobbyistterminated", "lobbyistdetails"])

# Save the values to a CSV file
CSV.open("data/clients#{$year}_lobbyists.csv","w") do |csv|
$masterlist.each { |row|
  csv << row
}
end