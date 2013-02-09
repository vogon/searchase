require 'sqlite3'

class CacheSqlite
	def initialize(table_name, pathname)
		@table_name = table_name

		@db = SQLite3::Database.new(pathname)
		@db.execute <<-SQL
			create table if not exists #{table_name} (
				id varchar(32) constraint id_unique unique on conflict fail,
				content text
			);
			create unique index if not exists dbsnp_id on #{table_name} (
				id asc
			);
		SQL
	end

	def open(id, &block)
		record = @db.execute("SELECT xml FROM #{@table_name} WHERE id = ?",
							 id)[0]
		
		if record then
			io = StringIO.new(record[0])
		end

		if block != nil then
			block.(io)
		else
			return io
		end
	end

	def write(id, xml)
		puts "insert"
		puts @db.execute("INSERT OR REPLACE INTO #{@table_name} (id, xml) VALUES (?, ?)",
						 id, xml)
	end

	def exists?(id)
		@db.execute("SELECT COUNT(id) FROM #{@table_name} WHERE id = ?", id) do |result|
			return result[0][0] > 0
		end
	end

	def delete(id)
		@db.execute("DELETE FROM #{@table_name} WHERE id = ?", id)
	end

	def flush
	end
end
