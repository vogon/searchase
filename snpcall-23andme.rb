require './snpcall'

class SNPCall
	attr_accessor :chr
	attr_accessor :position

	def SNPCall.load_23andme_dump(filename)
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

			snp = SNPCall.new
			snp.id, snp.chr, snp.position, snp.call = fields

			snps[snp.id] = snp
		end

		snps
	end
end
