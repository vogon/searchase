require './config'
require './dbsnp'

path = "./dbsnp_cache"

Dir.new(path).each do |filename|
	pathname = "#{path}/#{filename}"

	puts pathname

	begin
		File.open(pathname, "r") do |io|
			rsid = File.basename(filename, ".xml").to_i

			DbSNP::CACHE.write(rsid, io.read)
		end
	rescue Errno::EACCES
	end
end