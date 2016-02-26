require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'fileutils'

$masterlist = []
$errorlog = []
$lobbylist = []
$lobbyists = []
$exclusionlist = []
$indylobbyists = []

# Change the working directory
Dir.chdir("C:/Data/Lobbyists/")

# Set the year
puts "Specify the year, please."
$year = gets
$year = $year.chomp

# Read the lobbylist CSV file
CSV.foreach("lobbylists/lobbylist#{$year}.csv") do |row|
  $lobbylist << row
end
puts "Added each row from lobbylist#{$year}.csv to the $lobbylist"

# Examine the $lobbylist and identify all registered lobbyists
$lobbylist.each {|entry|
  @id = entry[2].gsub("Summary.aspx?PeriodId=#{$year}&RefId=", "")
  if entry[0] == "Lobbyist"
    $lobbyists << @id
  end
}

# Capture the name of each HTML file in the directory
$htmlfiles = Dir["htmlfiles/#{$year}/*.html"]

# Isolate the ID number from each file name
$htmlfiles.map! {|filename|
  @fullname = filename
  @id = filename.gsub("htmlfiles/#{$year}/", "")
  @id.gsub!(".html", "")
  filename = [@id, @fullname]
}

def findentitylobbyists(id,htmlfile)
  @id = id
  @htmlfile = htmlfile
  @htmlpage = Nokogiri::HTML(open("#{@htmlfile}"))
  @type = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegType']").text
  if ($lobbyists.include? @id) && (@type == "Entity")
    $exclusionlist << @id
  end
end

def findindylobbyists(id,htmlfile)
  @id = id
  @htmlfile = htmlfile
  @htmlpage = Nokogiri::HTML(open("#{@htmlfile}"))
  @type = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegType']").text
  if ($lobbyists.include? @id) && (@type == "Lobbyist")
    $indylobbyists << @id
  end
end

# Scrape each HTML file to find lobbyists who work for firms
puts "Identifying lobbyists who work for lobbying firms."
$htmlfiles.each {|array| findentitylobbyists(array[0],array[1])}
puts "Entity lobbyists:"
puts $exclusionlist.count

# Scrape each HTML file to find independent lobbyists
puts "Identifying independent lobbyists."
$htmlfiles.each {|array| findindylobbyists(array[0],array[1])}
puts "Indy lobbyists:"
puts $indylobbyists.count

#$lobbylist.each {|array|
#  @id = array[0]
#  if $exclusionlist.exclude? @id
#    $indylobbyists << array
#  end
#}

## Delete the entry if @id appears on the $exclusionlist 
#$masterlist.delete_if {|array| $exclusionlist.include? array[0]}

## Save the values to a CSV file
#CSV.open("data/disclosure_urls_#{$year}.csv","w") do |csv|
#  $masterlist.each { |row|
#    csv << row
#  }
#end
#puts "Wrote the $masterlist to a CSV file."
#
## Save the missing disclosure reports to a CSV file
#CSV.open("data/disclosure_urls_#{$year}_errorlog.csv","w") do |csv|
#  $errorlog.each { |row|
#    csv << row
#  }
#end
#puts "Wrote the $errorlog to a CSV file."