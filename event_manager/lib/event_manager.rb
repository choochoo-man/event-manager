require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_homephone(homephone)
  # If the phone number is less than 10 digits, assume that it is a bad number
  # If the phone number is 10 digits, assume that it is good
  if homephone.length == 10
    homephone.to_s
  end
  # If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
  if homephone.length == 11 && homephone.chars.first = 1
    homephone = homephone.to_s[1..11]
    homephone.to_s
  end
  # If the phone number is 11 digits and the first number is not 1, then it is a bad number
  # If the phone number is more than 11 digits, assume that it is a bad number
  if homephone.length > 11 || (homephone.length == 11 && homephone.chars.first != 1) || homephone.length < 10
    homephone = 0000000000
    homephone.to_s
  end
end

 hourlist = []
 daylist = []

def peakregistrationhours(regdate, hourlist, daylist)
  date_time = regdate.split(" ")
  hour = (((Time.parse(date_time[1])).hour).to_s).rjust(2, "0")
  hourlist << hour
  day = DateTime.strptime(date_time[0], "%m/%d/%y").wday
  daylist << day
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  regdate = row[:regdate]
  peakregistrationhours(regdate, hourlist, daylist)
end

(01..24).each do |hours|
  tally = hourlist.count(hours.to_s)
  puts "#{tally} people registered during the #{hours} hour"
end
DAYNAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]


(0..6).each do |days|
  tally = daylist.count(days)
  puts "#{tally} people registered during #{DAYNAMES[days]}"
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_homephone(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end