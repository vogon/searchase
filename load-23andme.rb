require './snp'

# loader for 23andme call files
module MeAnd23
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

snps = MeAnd23.load_23andme_dump('C:\Users\Colin\Documents\GitHub\snp-rarity-hack\genome_Colin_Bayer_Full_20121117005042.txt')
puts snps["rs5907"]