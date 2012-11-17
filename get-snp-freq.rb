require 'nokogiri'

f = open("#{ARGV[0]}.xml")
xml = Nokogiri::XML(f)

elset = xml.css('ExchangeSet Rs Frequency')

elset.count == 1 or fail "weird number of frequencies"
puts elset[0]['freq']
