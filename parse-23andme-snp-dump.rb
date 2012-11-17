class TwentyThreeSNP
	attr_accessor :id
	attr_accessor :chr
	attr_accessor :position
	attr_accessor :call
end

def parse_23andme_snp_dump(filename)
	io = open(filename)
	snps = {}

	line_number = 0

	io.each_line do |line|
		line_number += 1

		if line =~ /#/ then
			# puts "ignored comment"
			next
		end

		fields = line.strip.split("\t")

		snp = TwentyThreeSNP.new
		snp.id, snp.chr, snp.position, snp.call = fields

		snps[snp.id] = snp
	end

	snps
end