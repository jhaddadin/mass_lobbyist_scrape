require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'fileutils'

$masterlist = []
$totaldonations = []
$errorlog = []

# Change the working directory
Dir.chdir("C:/Data/Lobbyists/")

## Set the year
#puts "Specify the year, please."
#$year = gets
#$year = $year.chomp

$year = "2014"

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
  @nodonationscheck = ""
  
  puts "Scraping #{@htmlfile}"

  if @type == "Lobbyist"
    @donations = @htmlpage.xpath("//table[@id='ContentPlaceHolder1_DisclosureReviewDetail1_grdvCampaignContribution']//tr[@class='GridItem']").map{|tr| tr.children.map{|entry| entry.content.strip unless entry.text? == true}.compact!}
    if @donations != []
      @donations.each{|subarray| subarray.insert(0, @refid)}
      @total = @donations.pop
      @donations.each{|subarray| $masterlist << subarray}
      puts "Added donations from lobbyist #{@refid}, period #{@period} to the masterlist."
      $totaldonations << [@total[0], @period, @total[4]]
      puts "Lobbyist #{@total[0]} made a total of #{@total[4]} contributions during period #{@period}."
    else
      @nodonationscheck = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_DisclosureReviewDetail1_grdvCampaignContribution']/tr/td").text
      if @nodonationscheck == "No campaign contributions were filed for this disclosure reporting period."
        $totaldonations << [@refid, @period, "$0.00"]
        puts "Lobbyist #{@refid} reported no campaign contributions during period #{@period}."
      else
        $errorlog << [@refid, @period]
        puts "Added lobbyist #{@refid}, #{@period} to the error log."
      end
    end
  end
  
  if @type == "Entity"
    @donations = @htmlpage.xpath("//table[@id='ContentPlaceHolder1_DisclosureReviewDetail1_grdvCampaignContribution']//tr[@class='GridItem']").map{|tr| tr.children.map{|entry| entry.content.strip unless entry.text? == true}.compact!}
    if @donations != []
      @donations.each{|subarray| subarray.insert(0, @refid)}
      @donations.each{|subarray| subarray.delete_at(2)}
      @total = @donations.pop
      @donations.each{|subarray| $masterlist << subarray}
      puts "Added donations from entity #{@refid}, period #{@period} to the masterlist."
      $totaldonations << [@total[0], @period, @total[4]]
      puts "Entity #{@total[0]} made a total of #{@total[4]} contributions during period #{@period}."
    else
      @nodonationscheck = @htmlpage.xpath("//*[@id='ContentPlaceHolder1_DisclosureReviewDetail1_grdvCampaignContribution']/tr/td").text
      if @nodonationscheck == "No campaign contributions were filed for this disclosure reporting period."
        $totaldonations << [@refid, @period, "$0.00"]
        puts "entity #{@refid} reported no campaign contributions during period #{@period}."
      else
        $errorlog << [@refid, @period]
        puts "Added entity #{@refid}, #{@period} to the error log."
      end
    end
  end
  
end

# Scrape each HTML file
puts "Gathering information about donations by each lobbyist."
$htmlfiles.each {|array| tablescrape(array[0],array[1],array[2],array[3])}

# Insert column headings into the first row of the $masterlist
$masterlist.insert(0, ["refid", "date", "recipient", "office", "amount"])

# Insert column headings into the first row of the $masterlist
$totaldonations.insert(0, ["refid", "period", "amount"])

# Remove commas and dollar signs from all amounts
puts "Removing commas and dollar signs."
$masterlist.each{|subarray| subarray[4].gsub!("$", "")}
$masterlist.each{|subarray| subarray[4].gsub!(",", "")}
$totaldonations.each{|subarray| subarray[2].gsub!("$", "")}
$totaldonations.each{|subarray| subarray[2].gsub!(",", "")}

# Remove extraneous words
$masterlist.each{|subarray| subarray[2].gsub!("Committee to Elect ","")}
$masterlist.each{|subarray| subarray[2].gsub!("CTE ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Campaign to Elect ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Committee to Re-Elect ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Committee to Re-elect ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Committee to re-elect ","")}
$masterlist.each{|subarray| subarray[2].gsub!("State Senator ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Sen. ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Senator ","")}
$masterlist.each{|subarray| subarray[2].gsub!("State Representative ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Representative ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Rep. ","")}
$masterlist.each{|subarray| subarray[2].gsub!("Boston City Councilor ","")}
$masterlist.each{|subarray| subarray[2].gsub!(" for Governor","")}
$masterlist.each{|subarray| subarray[2].gsub!(" for Attorney General","")}

# Save the values to a CSV file
CSV.open("data/disclosure_donations_#{$year}.csv","w") do |csv|
$masterlist.each { |row|
  csv << row
}
end

# Save total contributions a CSV file
CSV.open("data/disclosure_donations_total_#{$year}.csv","w") do |csv|
$totaldonations.each { |row|
  csv << row
}
end

# Save the error log to a CSV file
if $errorlog != []
  CSV.open("data/disclosure_donations_#{$year}_errorlog.csv","w") do |csv|
  $errorlog.each { |row|
    csv << row
  }
end
end