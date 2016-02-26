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

def tablescrape(id,htmlfile)
  @id = id
  @htmlfile = htmlfile
  @htmlpage = Nokogiri::HTML(open("#{@htmlfile}"))
  @type = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblRegType']").text

  # Count the number of amendments filed for each disclosure
  @d1pane = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_panelD1Version']").text
  @d2pane = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_panelD2Version']").text
  @d1amendments = @d1pane.scan(/amended/).count
  @d2amendments = @d2pane.scan(/amended/).count
  
  unless @d1amendments == 0
    @d1amendmentscount = @d1amendments - 1
  end
  
  unless @d2amendments == 0
    @d2amendmentscount = @d2amendments - 1
  end

  # Record the filing period for each disclosure
  @d1period = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_hlnkD1Version']").text
  @d1period.gsub!("View disclosure reporting details filed for the period ", "")
  @d2period = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_hlnkD2Version']").text
  @d2period.gsub!("View disclosure reporting details filed for the period ", "")

  if @d1amendments == 0
    @d1url = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_hlnkD1Version']/@href").text
    @d1amended = "No"
    @d1amendeddate = ""
  else
    @d1url = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptD1Version_hlnkDiscDetails_#{@d1amendmentscount}']/@href").text
    @d1amended = "Yes"
    @d1amendeddate = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_RptD1Version_hlnkDiscDetails_#{@d1amendmentscount}']").text
    @d1amendeddate.gsub!("Report amended ", "")
  end

  if @d2amendments == 0
    @d2url = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_hlnkD2Version']/@href").text
    @d2amended = "No"
    @d2amendeddate = ""
  else
    @d2url = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_rptD2Version_hlnkDiscDetails_#{@d2amendmentscount}']/@href").text
    @d2amended = "Yes"
    @d2amendeddate = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_rptD2Version_hlnkDiscDetails_#{@d2amendmentscount}']").text
    @d2amendeddate.gsub!("Report amended ", "")
  end

  @subarray1 = [@id, @d1period, @d1url, @type, @d1amended, @d1amendeddate]
  @subarray2 = [@id, @d2period, @d2url, @type, @d2amended, @d2amendeddate]

  if @subarray1[1] == ""
    $errorlog << @subarray1
    puts "Wrote an entry for #{@id} to the error log."
  else
    $masterlist << @subarray1
    puts "Wrote #{@id}, disclosure period #{@d1period} to the master list."
  end

  if @subarray2[1] == ""
    $errorlog << @subarray2
    puts "Wrote an entry for #{@id} to the error log."
  else
    $masterlist << @subarray2
    puts "Wrote #{@id}, disclosure period #{@d2period} to the master list."
  end

end

# Scrape each HTML file to find lobbyists who work for firms
puts "Identifying lobbyists who work for lobbying firms."
$htmlfiles.each {|array| findentitylobbyists(array[0],array[1])}

# Scrape each HTML file for disclosure URLs
$htmlfiles.each {|array| tablescrape(array[0],array[1])}

# Delete the entry if @id appears on the $exclusionlist 
$masterlist.delete_if {|array| $exclusionlist.include? array[0]}
$errorlog.delete_if {|array| $exclusionlist.include? array[0]}

# Save the values to a CSV file
CSV.open("data/disclosure_urls_#{$year}.csv","w") do |csv|
  $masterlist.each { |row|
    csv << row
  }
end
puts "Wrote the $masterlist to a CSV file."

# Save the missing disclosure reports to a CSV file
CSV.open("data/disclosure_urls_#{$year}_errorlog.csv","w") do |csv|
  $errorlog.each { |row|
    csv << row
  }
end
puts "Wrote the $errorlog to a CSV file."