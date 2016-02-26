require 'rubygems'
require 'csv'
require 'open-uri'
require 'fileutils'

$masterlist = []

# Change the working directory
Dir.chdir("C:/Data/Lobbyists/")

# Set the year
puts "Specify the year, please."
$year = gets
$year = $year.chomp

# Read the CSV file
CSV.foreach("lobbylists/lobbylist#{$year}.csv") do |row|
  $masterlist << row
end
puts "Added each row from lobbylist#{$year}.csv to the $masterlist"

# Delete the column headings in the first row
$masterlist.delete_at(0)
puts "Deleted the column headings from the first row."

# Download each HTML page
$masterlist.each{ |row|
  @type = row[0]
  @name = row[1]
  @url = row[2]
  @refid = @url.gsub("Summary.aspx?PeriodId=#{$year}&RefId=", "")
  puts "Writing HTML file for #{@name} (#{@refid}.html)"
    
  open("htmlfiles/#{$year}/#{@refid}.html", "wb") do |file|
    open("http://www.sec.state.ma.us/LobbyistPublicSearch/#{@url}") do |uri|
     file.write(uri.read)
   end
  end
}

puts "Success!"