require './snp'

# loader for 23andme call files
class SNP
	def self.load_23andme_dump(filename)
		File.open(filename) do |io|
			snps = {}

			io.each_line do |line|
				if line =~ /^#/ then
					# comment; ignore
					next
				end

				id, chr, position, call = line.strip.split("\t")

				snps[id] = SNP.new(id) do |snp|
					snp.chr = chr

					snp.assays[filename] = Assay.new(filename) do |assay|
						assay.genotype = call
					end
				end
			end

			snps
		end
	end
end

if __FILE__ == $0 then
	snps = SNP.load_23andme_dump('C:\Users\Colin\Documents\GitHub\snp-rarity-hack\genome_Colin_Bayer_Full_20121117005042.txt')
	rs5907 = snps["rs5907"]
	puts rs5907.inspect

	require './load-dbsnp'

	dbsnp_rs5907 = SNP.load_dbSNP("rs5907")
	puts dbsnp_rs5907.inspect

	merged = rs5907.merge(dbsnp_rs5907)
	puts merged.inspect
end