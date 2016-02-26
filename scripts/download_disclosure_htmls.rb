require 'rubygems'
require 'csv'
require 'open-uri'
require 'fileutils'

# Change the working directory
Dir.chdir("C:/Data/Lobbyists/")

# Set the year
puts "Specify the year, please."
$year = gets
$year = $year.chomp

def getdisclosures
  # Read the CSV file
  @disclosureurls = []
  CSV.foreach("data/disclosure_urls_#{$year}.csv") do |row|
    @disclosureurls << row
  end
  
  # Download each HTML page
  @disclosureurls.each{ |row|
    @refid = row[0]
    @period = row[1]
    @url = row[2]
    @type = row[3]
    
    @period.gsub!(/1\/1\/\d\d\d\d - 6\/30\/\d\d\d\d/, "P1")
    @period.gsub!(/7\/1\/\d\d\d\d-12\/31\/\d\d\d\d/, "P2")
    
#    @disclosure = @url.gsub("CompleteDisclosure.aspx?DisclosureId=", "")
#    @disclosure.gsub!(/&Version=.+/, "")
#    @version = @url.gsub(/CompleteDisclosure.aspx.DisclosureId=.+&Version=/, "")
    
    puts "Writing HTML file for #{@refid}, period #{@period}."
    
    open("htmlfiles/#{$year}/disclosures/#{@refid}_#{@period}_#{@type}.html", "wb") do |file|
     open("http://www.sec.state.ma.us/LobbyistPublicSearch/#{@url}") do |uri|
       file.write(uri.read)
      end
    end
   }
end

getdisclosures