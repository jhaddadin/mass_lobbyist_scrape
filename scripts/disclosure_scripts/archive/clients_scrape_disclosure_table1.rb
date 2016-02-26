require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'fileutils'

$masterlist = []
$errorlog = []
$duplicatecheck = []
$changed = []

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
  @refid.gsub!("htmlfiles/#{$year}/disclosures/", "")
  @period = @fullname[/.+_P(.*?)_.+/, 1]
  @type = @fullname.gsub(/.+_.+_/, "")
  @type.gsub!(".html", "")
  filename = [@refid, @type, @period, @fullname]
}

def tablescrape(refid,type,period,fullname)
  @refid = refid
  @type = type
  @period = period
  @htmlfile = fullname
  @htmlpage = Nokogiri::HTML(open("#{@htmlfile}"))
  
  # Identifying information
  @header = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblDisclosureHeader']/b").text
  @header.gsub!(" disclosure reporting period", "")
  @periodlongform = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_lblYear']/b").text
  @periodlongform.gsub!(/01\/01\/\d\d\d\d - 06\/30\/\d\d\d\d/, "1")
  @periodlongform.gsub!(/07\/01\/\d\d\d\d - 12\/31\/\d\d\d\d/, "2")
  
  if (@header == "Client") && (@type == "Client") && (@period == @periodlongform)
    @firstname = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientAuthorizingOfficerFirstName']").text
    @middlename = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientAuthorizingOfficerMiddleName']").text
    @lastname = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientAuthorizingOfficerLastName']").text
    @company = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientCompany']").text
    @street1 = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientStreet1']").text
    @citystatezip = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblCityStateZip']").text
    @country = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientCountry']").text
    @phone = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientPhone']").text
    @email = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_CRegistrationInfoReview1_lblClientPrimaryEmail']").text
    @subarray = [@refid, @type, @firstname, @middlename, @lastname, @company, @street1, @citystatezip, @country, @phone, @email]
    $masterlist << @subarray
    puts "Added #{@refid}, period #{@period} to the list."
  elsif (@header == "Client") || (@type == "Client")
    @subarray = [@refid, @type, @period, @htmlfile]
    $errorlog << @subarray
    puts "Wrote an entry for #{@refid} to the error log."
  end
end

# Scrape each HTML file
$htmlfiles.each {|array| tablescrape(array[0],array[1],array[2],array[3])}

# Delete duplicate entries from the $masterlist
$masterlist = $masterlist.uniq

# Check to see if contact information has changed between P1 and P2 for each lobbyist
$masterlist.each {|subarray| $duplicatecheck << subarray[0]}
$changed = $duplicatecheck.select{|element| $duplicatecheck.count(element) > 1 }
$changed = $changed.uniq

# Insert column headings into the first row of the $masterlist
$masterlist.insert(0, ["refid", "type", "firstname", "middlename", "lastname", "company", "street1", "citystatezip", "country", "phone", "email"])

# Save the values to a CSV file
CSV.open("data/client_disclosure_table1_#{$year}.csv","w") do |csv|
$masterlist.each { |row|
  csv << row
}
end

# Save errors to a CSV file. These are disclosure reports that have some kind of mismatch in the type or period.
if $errorlog != []
  CSV.open("data/client_disclosure_table1_#{$year}_errorlog.csv","w") do |csv|
    $errorlog.each { |row|
     csv << row
   }
  end
end

# Save entries with mismatched contact information between P1 and P2 to a CSV file
if $changed != []
  CSV.open("data/client_disclosure_table1_#{$year}_changelog.csv","w") do |csv|
    $changed.each { |row|
      csv << row
    }
  end
end