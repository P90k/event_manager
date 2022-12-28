# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file| # create and write to the file.
    file.puts form_letter
  end
end

def clean_phone_number(number)
  return number if number.length == 10
  return number.split('')[1..number.length].join if number.length == 11 && (number[0] == '1')

  'Bad number'
end

def find_max_values_hash(hash)
  max_value = hash.max_by { |_key, value| value }[1]
  all_max_values = hash.select { |_key, value| value == max_value }
  all_max_values.keys
end

def translate_integer_weekday(weekday_integer_array)
  weekdays = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
  weekday_integer_array.map { |element| weekdays[element] }
end

puts 'Event Manager initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
weekday_hash = Hash.new(0)

registration_time = Hash.new(0)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislator_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  date_time_object = DateTime.strptime(row[:regdate], '%m/%d/%Y %H:%M')
  registration_time[date_time_object.hour] += 1
  weekday_hash[date_time_object.wday] += 1
  save_thank_you_letter(id, form_letter)
end
most_reg_hours = find_max_values_hash(registration_time)
most_reg_weekdays = translate_integer_weekday(find_max_values_hash(weekday_hash))
puts "\n"
puts "Hour(s) of most registrations: \n#{most_reg_hours.join(' & ')}"
puts "\n"
puts "Weekday(s) of most registrations: \n#{most_reg_weekdays.join(' & ')}"
