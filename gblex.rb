require './entreznuc'

TOKENS = 
	{
		nucid: /^[A-Z_]+[0-9]+\.[0-9]+/,
		range: /^([0-9]+)\.\.([0-9]+)/,
		int: /^[0-9]+/,
		colon: /^\:/,
		comma: /^\,/,
		l_paren: /^\(/,
		r_paren: /^\)/,
		join: /^join/,
		complement: /^complement/,
		gap: /^gap/,
	}

class Token
	def initialize(id, match)
		self.id = id
		self.match = match
	end

	def to_s
		"#{id}: #{match[0]}"
	end

	attr_accessor :id
	attr_accessor :match
end

class Xref
	def initialize(gbid, first, last)
		self.gbid = gbid
		self.first = first
		self.last = last
	end

	def length
		last - first + 1
	end

	def [](ofs)
		puts "Xref[#{ofs}]"

		resolve! if proxied.nil?

		proxied[ofs - first + 1]
	end

	def orientation(ofs)
		resolve! if proxied.nil?

		if proxied.is_a? String then
			1
		else
			proxied.orientation(ofs)
		end
	end

	private
	def resolve!
		xml = Nucleotide[gbid]

		if xml.css("GBSeq_sequence").length > 0 then
			# just a sequence.
			self.proxied = xml.css("GBSeq_sequence")[0].text
		elsif xml.css("GBSeq_contig").length > 0 then
			# contig; contains other xrefs and stuff.
			self.proxied = parse_string(xml.css("GBSeq_contig")[0].text)
		else
			fail "unexpected xref type"
		end
	end

	attr_accessor :gbid
	attr_accessor :first, :last

	private
	attr_accessor :proxied
end

class Complement
	def initialize(arg)
		self.arg = arg
	end

	def length
		arg.length
	end

	def [](ofs)
		puts "Complement[#{ofs}]"

		#complement
		arg[ofs]
	end

	def orientation(ofs)
		-(arg.orientation(ofs))
	end

	attr_accessor :arg
end

class Gap
	def initialize(n)
		self.n = n
	end

	def length
		self.n
	end

	def [](ofs)
		puts "Gap[#{ofs}]"

		#bounds check
		"N"
	end

	def orientation(ofs)
		1
	end

	attr_accessor :n
end

class Join
	def initialize(args)
		self.args = args
	end

	def length
		args.map {|arg| arg.length}.inject(:+)
	end

	def [](ofs)
		puts "Join[#{ofs}]"

		child, child_ofs = locate(ofs)
		child[child_ofs]
	end

	def orientation(ofs)
		child, child_ofs = locate(ofs)
		child.orientation(child_ofs)
	end

	private
	def locate(ofs)
		consumed = 0

		args.each do |arg|
			if consumed + arg.length < ofs then
				consumed += arg.length
			else
				return arg, ofs - consumed
			end
		end

		fail "off the end"
	end

	attr_accessor :args
end

def lex(s)
	stream = []
	rest = s

	while rest != "" do
		matched = false

		TOKENS.each do |id, re|
			if rest =~ re then
				# match; pull off a token and move on
				tok = Token.new(id, $~)
				stream << tok
				rest = rest[($~.end(0))..-1]

				matched = true
				break
			end
		end

		fail "no matching token at #{rest}" if !matched
	end

	return stream
end

def expect(stream, idx, id)
	fail "failed expectation: #{stream[idx].id}, not expected #{id}" if id != stream[idx].id
end

def parse(stream)
	next_idx, ast = parse_seq(stream, 0)
	fail "weird next_idx: #{next_idx} not #{stream.length}" if next_idx != stream.length

	return ast
end

def parse_string(str)
	stream = lex(str)
	return parse(stream)
end

def parse_seq(stream, idx)
	tok = stream[idx]

	case tok.id
	when :nucid then parse_xref(stream, idx)
	when :join then parse_join(stream, idx)
	when :gap then parse_gap(stream, idx)
	when :complement then parse_complement(stream, idx)
	else fail "unexpected token at parse_seq (#{tok.id})"
	end
end

def parse_join(stream, idx)
	expect(stream, idx, :join)
	expect(stream, idx + 1, :l_paren)

	args = []
	arg_idx = idx + 2
	next_idx = nil

	loop do
		next_idx, arg = parse_seq(stream, arg_idx)
		args << arg

		if stream[next_idx].id == :comma then
			arg_idx = next_idx + 1
		else
			break
		end
	end

	expect(stream, next_idx, :r_paren)

	return next_idx + 1, Join.new(args)
end

def parse_gap(stream, idx)
	expect(stream, idx, :gap)
	expect(stream, idx + 1, :l_paren)
	expect(stream, idx + 2, :int)
	expect(stream, idx + 3, :r_paren)

	return idx + 4, Gap.new(stream[idx + 2].match[0].to_i)
end

def parse_complement(stream, idx)
	expect(stream, idx, :complement)
	expect(stream, idx + 1, :l_paren)

	next_idx, arg = parse_seq(stream, idx + 2)

	expect(stream, next_idx, :r_paren)

	return next_idx + 1, Complement.new(arg)
end

def parse_xref(stream, idx)
	expect(stream, idx, :nucid)
	expect(stream, idx + 1, :colon)
	expect(stream, idx + 2, :range)

	return idx + 3, Xref.new(stream[idx].match[0], stream[idx + 2].match[1].to_i, stream[idx + 2].match[2].to_i)
end

if __FILE__ == $0 then
	fail if ARGV.length < 2

	ofs = ARGV[1].to_i
	top = Nucleotide[ARGV[0]]
	top_seq = parse_string(top.css("GBSeq_contig")[0].text)

	puts "sequence: #{top_seq[ofs]}"
	puts "orientation: #{top_seq.orientation(ofs)}"

	# stream = lex("join(gap(10000),gap(12990000),gap(3000000),gap(50000),NT_028395.3:1..647850,gap(150000),NT_011519.10:1..3661581,gap(100000),NT_011520.12:1..29755346,gap(50000),NT_011526.7:1..829789,gap(50000),gap(10000))")
	# puts parse_seq(stream, 0).inspect
end