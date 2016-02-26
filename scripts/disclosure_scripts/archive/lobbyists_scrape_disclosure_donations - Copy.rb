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
$htmlfiles = Dir["htmlfiles/#{$year}/disclosures/*.html"]

# Isolate the ID number from each file name
$htmlfiles.map! {|filename|
  @fullname = filename
  @refid = @fullname.gsub(/_.+/, "")
  @period = @fullname[/.+_P(.*?)_.+/, 1]
  @type = @fullname.gsub(/.+_.+_/, "")
  @type.gsub!(".html", "")
  filename = [@refid, @type, @period, @fullname]
}

## Isolate the ID number from each file name
#$htmlfiles.map! {|filename|
#  @fullname = filename
#  @refid = @fullname.gsub(/_.+/, "")
#  @disclosureid = @fullname.sub(/_\d+.html/, "")
#  @disclosureid.sub!(/\d+_/, "")
#  @version = @fullname.gsub(/.+_.+_/, "")
#  @version = @version.gsub!(".html", "")
#  filename = [@refid, @fullname, @disclosureid, @version]
#}

def tablescrape(refid,type,period,fullname)
  @refid = refid
  @type = type
  @period = period
  @htmlfile = fullname
  @htmlpage = Nokogiri::HTML(open("#{@htmlfile}"))
  @counter = 0
  
  # Identifying information
  @name = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegistrantName']").text
  @year = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblYear']").text
  @period = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblYear']/b").text
  
#  # Count the number of lobbyists the entity employs
#  @lobbyistarray = []
#  @lobbyistdiv = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_pnlLobbyistInfo']/table/tr/td/a[@class='BlueLinks']")
#  @lobbyistdiv.each {|lobbyist|
#    @lobbyistarray << lobbyist.text
#    }
#  @counter = @lobbyistarray.count
#  
#  # Scrape each lobbyist from the div until @scrapecount matches @counter
#  @scrapecount = 0
#  
#  until @scrapecount == @counter
#  @subarray = []
#  
#  # Clean up payments by removing commas and dollar signs
#  @lobbyistamount.gsub!(",", "")
#  @lobbyistamount.gsub!("$", "")
#
#  @subarray = [@id, @name, @year, @lobbyistrefid, @lobbyistname, @lobbyistamount, @lobbyistemployed, @lobbyistterminated]
#  $masterlist << @subarray
#  puts "Added #{@id} to the list."
#  @scrapecount = @scrapecount + 1
#  end
end

## Scrape each HTML file
#$htmlfiles.each {|array| tablescrape(array[0],array[1])}
#
## Insert column headings into the first row of the $masterlist
#$masterlist.insert(0, ["id"])
#
## Save the values to a CSV file
#CSV.open("data/disclosures_lobbyist_donations_#{$year}.csv","w") do |csv|
#$masterlist.each { |row|
#  csv << row
#}
#end