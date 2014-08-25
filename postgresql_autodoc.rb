#!/usr/bin/env ruby

# $Header$
#  Imported 1.22 2002/02/08 17:09:48 into sourceforge

# Postgres Auto-Doc Version 1.41

# License
# -------
# Copyright (c) 2001-2009, Rod Taylor
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1.   Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#
# 2.   Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
# 3.   Neither the name of the InQuent Technologies Inc. nor the names
#      of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written
#      permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE FREEBSD
# PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# About Project
# -------------
# Various details about the project and related items can be found at
# the website
#
# http://www.rbt.ca/autodoc/

require 'optparse'
require 'ostruct'
require 'pg'

options = OpenStruct.new(
   :database => nil,
   :host => 'localhost',
   :types => []
)

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"
  opts.separator ""
  opts.separator "Specific options:"
  opts.on("-d", "--database dbname", String, "Specify database name to connect to (default: $database)") do |value|
    options.database = value
  end
  opts.on("-f", "--file file", String, "Specify output file prefix (default: $database)") do |value|
    options.file = value
  end
  opts.on("-h", "--host host", String, "Specify database server host (default: localhost)") do |value|
    options.host = value
  end
  opts.on("-p", "--port port", String, "Specify database server port (default: 5432)") do |value|
    options.port = value.to_i
  end
  opts.on("-u", "--user username", String, "Specify database username (default: $dbuser)") do |value|
    options.user = value
  end
  opts.on("--password [pw]", String, "Have $basename prompt for a password or user 'pw'") do |value|
    options.password = value
  end
  opts.separator ""
  opts.on("-l", "--template-path path", String, "Path to the templates (default: @@TEMPLATE-DIR@@)") do |value|
    options.path = value
  end
  opts.on("-t", "--output-type type", String, "Type of output wanted (default: All in template library)") do |value|
    options.types.push value
  end
  opts.separator ""
  opts.on("-s", "--schema dbname", String, "Specify a specific schema to match.  Technically this is a",
                                           "regular expression but anything other than a specific name",
					   "may have unusual results.") do |value|
    options.schema = value
  end
  opts.separator ""
  opts.on("--statistics", nil,             "In 7.4 and later, with the contrib module pgstattuple installed",
                                           "we can gather statistics on the tables in the database (average",
					   "size, free space, disk space used, dead tuple counts, etc.) This",
					   "is disk intensive on large databases as all pages must be visited.") do |value|
    options.statistics = true
  end
  opts.separator ""
  opts.on("--help", nil, "This help page") do |value|
    puts opts
    exit
  end
  opts.on("--version", nil, "output version information and exit") do |value|
    puts VERSION
    exit
  end
end.parse!

require 'pp'

class Database
  @@databases = Hash.new{ |h, k| h[k] = Database.new(k) }
  attr_accessor :comment
  def self.[](x)
    @@databases[x]
  end
  def self.all
    @@databases
  end
  def self.each
    @@databases.each do |k, v|
      yield v
    end
  end
  attr_accessor :name
  attr_accessor :comment
  def initialize(n)
    @name = n
    @schemas = Hash.new{ |h, k| h[k] = Schema.new(k, n) }
  end
  def get_schema(name)
    @schemas[name]
  end
  def get_column(name, table_name, column_name)
      @schemas[name].get_table(table_name).get_column(column_name)
  end
  def each_schema
    @schemas.each do |n, v|
      yield v
    end
  end
  class Schema
    attr_accessor :comment
    attr_reader :name
    def initialize(n, database)
      @name = n
      @database = database
      @tables = Hash.new{ |h, k| h[k] = Table.new(k, n, @database) }
    end
    def get_column(table_name, column_name)
      @tables[table_name].get_column(column_name)
    end
    def get_table(name)
      unless @tables[name].schema
raise "error"
      end
      @tables[name]
    end
    def each_table
      @tables.each_value.sort{ |a, b| a.name <=> b.name }.each do |n|
	yield n
      end
    end
    class Table
      class Column
        class Constraint
	  attr_reader :name
	  attr_accessor :type
	  attr_accessor :schema
	  attr_accessor :table
	  attr_accessor :column
	  attr_accessor :schema
	  def initialize(name)
	    @name = name
	  end
	  def set_fkcolumn(schema, table, column)
	    @schema = schema
	    @table = table
	    @column = column
	    @fk = true
	  end
        end
	attr_reader :name
	attr_accessor :order
	attr_accessor :primary_key
	attr_accessor :fktable
	attr_accessor :type
	attr_accessor :comment
	attr_accessor :default
	attr_accessor :not_null
	def initialize(name)
	  @name = name
	  @constraints = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	  @indexes = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	  @inherits = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	  @description = ''
	end
	def add_constraint(name, definition)
	  case definition
	  when :unique
	    @unique = true
	    @description += 'UNIQUE'
	  when :primary_key
	    @primary_key = true
	    @description += 'PRIMARY KEY'
	  else
	    raise definition.to_s
          end
	  @constraints[name].type = definition || 'none'
	  @constraints[name]
	end
        def get_constraint(name)
	  @constraints[name]
        end
	def each_constraint
	  @constraints.each do |k, v|
	    yield v
	  end
	end
	def foreign_key
	  ret = Array.new
	  @constraints.each do |k, v|
	    if v.type == :foreign_key
              ret.push [v.schema, v.table, v.column].join('.')
	    end
	  end
	  ret.join(', ')
	end
	def description
	  ret = @description
	  if @not_null && !@primary_key
	    ret += ' NOT NULL'
	  end
	  ret
	end
	def each_index
	  @indexes.each do |k, v|
	    yield v
	  end
	end
	def each_inherit
	  @inherits.each do |k, v|
	    yield v
	  end
	end
      end
      class User
	attr_accessor :granted_by
	attr_accessor :raw_permissions
	def initialize(name)
          @name
        end
      end
      attr_reader :name
      attr_accessor :type
      attr_accessor :table_description
      attr_accessor :view_definition
      attr_accessor :schema
      def initialize(name, schema, database)
	@name = name
	@schema = schema
	@database = database
	@columns = Hash.new{ |h, k| h[k] = Column.new(k) }
	@users = Hash.new{ |h, k| h[k] = User.new(k) }
	@inherite_from = Array.new
	@inherited_by = Array.new
	@indexes = Array.new
	@contraint = Hash.new
      end
      def set_permitions(a, b, c)
        user = @users[a]
        user.granted_by = c
        user.raw_permissions = b
      end
      def add_inherited_by(schema, table)
        @inherited_by.push [schema, table]
      end
      def add_inheritance(schema, table, cs, ct)
        @inherite_from.push [schema, table]
	Database[@database].get_schema(schema).get_table(table).add_inherited_by(@schema, @name)
      end
      def add_index(schema, table, index, indexdef, definition)
        @indexes.push [ schema, table, index, indexdef, definition ]
      end
      def get_column(name)
        column = @columns[name]
      end
      def each_column
        @columns.each do |k, v|
	  yield v
	end
      end
      def add_constraint(name, definition)
        @contraint[name] = definition
      end
    end # class Table
  end # class Schema
end # class Database

def database_collect(options)
  database_name = options.database
  host = options.host
  user = options.user
  password = options.password
  port = options.port
  conn = PGconn.open(:dbname => database_name, :host => host, :user => user, :password => password)

  database_name = conn.exec('select current_database() as database_name').first['database_name']

  system_schema_list = 'pg_catalog|pg_toast|pg_temp_[0-9]+|information_schema'

  conn.prepare('database', <<-SQL)
  SELECT pg_catalog.obj_description(oid, 'pg_database') as comment
    FROM pg_catalog.pg_database
   WHERE datname = $1
  SQL

  conn.prepare('constraint', <<-SQL)
  SELECT pg_get_constraintdef(oid) AS constraint_source
      , conname AS constraint_name
   FROM pg_constraint
  WHERE conrelid = $1
    AND contype = 'c';
  SQL

  # [ matchpattern, system_schema_list, schemapattern ]
  conn.prepare('tables', <<-SQL)
  SELECT nspname as namespace
      , relname as tablename
      , pg_catalog.pg_get_userbyid(relowner) AS tableowner
      , pg_class.oid
      , pg_catalog.obj_description(pg_class.oid, 'pg_class') as table_description
      , relacl
      , CASE
	WHEN relkind = 'r' THEN
	  'table'
	WHEN relkind = 's' THEN
	  'special'
	ELSE
	  'view'
	END as reltype
      , CASE
	WHEN relkind = 'v' THEN
	  pg_get_viewdef(pg_class.oid)
	ELSE
	  NULL
	END as view_definition
   FROM pg_catalog.pg_class
   JOIN pg_catalog.pg_namespace ON (relnamespace = pg_namespace.oid)
  WHERE relkind IN ('r', 's', 'v')
    AND relname ~ $1
    AND nspname !~ $2
    AND nspname ~ $3
  SQL
  #  sql_Tables .= qq{ AND relname IN ($table_out)} if defined($table_out);
  conn.prepare('columns', <<-SQL)
     SELECT attname as column_name
	  , attlen as column_length
	  , CASE
	    WHEN pg_type.typname = 'int4'
		 AND EXISTS (SELECT TRUE
			       FROM pg_catalog.pg_depend
			       JOIN pg_catalog.pg_class ON (pg_class.oid = objid)
			      WHERE refobjsubid = attnum
				AND refobjid = attrelid
				AND relkind = 'S') THEN
	      'serial'
	    WHEN pg_type.typname = 'int8'
		 AND EXISTS (SELECT TRUE
			       FROM pg_catalog.pg_depend
			       JOIN pg_catalog.pg_class ON (pg_class.oid = objid)
			      WHERE refobjsubid = attnum
				AND refobjid = attrelid
				AND relkind = 'S') THEN
	      'bigserial'
	    ELSE
	      pg_catalog.format_type(atttypid, atttypmod)
	    END as column_type
	  , CASE
	    WHEN attnotnull THEN
	      cast('NOT NULL' as text)
	    ELSE
	      cast('' as text)
	    END as column_null
	  , CASE
	    WHEN pg_type.typname IN ('int4', 'int8')
		 AND EXISTS (SELECT TRUE
			       FROM pg_catalog.pg_depend
			       JOIN pg_catalog.pg_class ON (pg_class.oid = objid)
			      WHERE refobjsubid = attnum
				AND refobjid = attrelid
				AND relkind = 'S') THEN
	      NULL
	    ELSE
	      adsrc
	    END as column_default
	  , pg_catalog.col_description(attrelid, attnum) as column_description
	  , attnum
       FROM pg_catalog.pg_attribute 
       JOIN pg_catalog.pg_type ON (pg_type.oid = atttypid) 
  LEFT JOIN pg_catalog.pg_attrdef ON (   attrelid = adrelid 
				     AND attnum = adnum)
      WHERE attnum > 0
	AND attisdropped IS FALSE
	AND attrelid = $1
  SQL

  conn.prepare('primary keys', <<-SQL)
  SELECT conname AS constraint_name
      , pg_catalog.pg_get_indexdef(d.objid) AS constraint_definition
      , CASE
	WHEN contype = 'p' THEN
	  'primary_key'
	ELSE
	  'unique'
	END as constraint_type
   FROM pg_catalog.pg_constraint AS c
   JOIN pg_catalog.pg_depend AS d ON (d.refobjid = c.oid)
  WHERE contype IN ('p', 'u')
    AND deptype = 'i'
    AND conrelid = $1
  SQL

  conn.prepare('foreign keys', <<-SQL)
  SELECT pg_constraint.oid
      , pg_namespace.nspname AS namespace
      , CASE WHEN substring(pg_constraint.conname FROM 1 FOR 1) = '\$' THEN ''
	ELSE pg_constraint.conname
	END AS constraint_name
      , conkey AS constraint_key
      , confkey AS constraint_fkey
      , confrelid AS foreignrelid
      , conrelid
   FROM pg_catalog.pg_constraint
   JOIN pg_catalog.pg_class ON (pg_class.oid = conrelid)
   JOIN pg_catalog.pg_class AS pc ON (pc.oid = confrelid)
   JOIN pg_catalog.pg_namespace ON (pg_class.relnamespace = pg_namespace.oid)
   JOIN pg_catalog.pg_namespace AS pn ON (pn.oid = pc.relnamespace)
  WHERE contype = 'f'
    AND conrelid = $1
    AND pg_namespace.nspname ~ $2
  SQL

# [ reloid, key ]
  conn.prepare('foreign key arg', <<-SQL)
SELECT attname AS attribute_name
     , relname AS relation_name
     , nspname AS namespace
  FROM pg_catalog.pg_attribute
  JOIN pg_catalog.pg_class ON (pg_class.oid = attrelid)
  JOIN pg_catalog.pg_namespace ON (relnamespace = pg_namespace.oid)
 WHERE attrelid = $1 
   AND attnum = $2
  SQL

  conn.prepare('indexes', <<-SQL)
  SELECT schemaname
      , tablename
      , indexname
      , substring(    indexdef
		 FROM position('(' IN indexdef) + 1
		  FOR length(indexdef) - position('(' IN indexdef) - 1
		 ) AS indexdef
      , indexdef as definition
   FROM pg_catalog.pg_indexes
  WHERE substring(indexdef FROM 8 FOR 6) != 'UNIQUE'
    AND schemaname = $1
    AND tablename = $2
  SQL

  conn.prepare('inheritance', <<-SQL)
SELECT parnsp.nspname AS par_schemaname
    , parcla.relname AS par_tablename
    , chlnsp.nspname AS chl_schemaname
    , chlcla.relname AS chl_tablename
 FROM pg_catalog.pg_inherits
 JOIN pg_catalog.pg_class AS chlcla ON (chlcla.oid = inhrelid)
 JOIN pg_catalog.pg_namespace AS chlnsp ON (chlnsp.oid = chlcla.relnamespace)
 JOIN pg_catalog.pg_class AS parcla ON (parcla.oid = inhparent)
 JOIN pg_catalog.pg_namespace AS parnsp ON (parnsp.oid = parcla.relnamespace)
WHERE chlnsp.nspname = $1
  AND chlcla.relname = $2
  AND chlnsp.nspname ~ $3
  AND parnsp.nspname ~ $3
  SQL

  # [ system_schema_list, schemapattern, matchpattern ]
  conn.prepare('function', <<-SQL)
SELECT proname AS function_name
    , nspname AS namespace
    , lanname AS language_name
    , pg_catalog.obj_description(pg_proc.oid, 'pg_proc') AS comment
    , proargtypes AS function_args
    , proargnames AS function_arg_names
    , prosrc AS source_code
    , proretset AS returns_set
    , prorettype AS return_type
 FROM pg_catalog.pg_proc
 JOIN pg_catalog.pg_language ON (pg_language.oid = prolang)
 JOIN pg_catalog.pg_namespace ON (pronamespace = pg_namespace.oid)
 JOIN pg_catalog.pg_type ON (prorettype = pg_type.oid)
WHERE pg_namespace.nspname !~ $1
  AND pg_namespace.nspname ~ $2
  AND proname ~ $3
  AND proname != 'plpgsql_call_handler';
  SQL

  conn.prepare('function_arg', <<-SQL)
SELECT nspname AS namespace
    , replace( pg_catalog.format_type(pg_type.oid, typtypmod)
	     , nspname ||'.'
	     , '') AS type_name
 FROM pg_catalog.pg_type
 JOIN pg_catalog.pg_namespace ON (pg_namespace.oid = typnamespace)
WHERE pg_type.oid = $1
  SQL

  # [ system_schema_list, schemapattern ]
  conn.prepare('schema', <<-SQL)
SELECT pg_catalog.obj_description(oid, 'pg_namespace') AS comment
    , nspname as namespace
 FROM pg_catalog.pg_namespace
WHERE pg_namespace.nspname !~ $1
  AND pg_namespace.nspname ~ $2;
  SQL

  conn.exec("set client_encoding to 'UTF-8'")

  if Gem::Version.new('7.3.0') >= 
     Gem::Version.new(conn.parameter_status('server_version')) 
   raise("PostgreSQL 7.3 and later are supported")
  end

  matchpattern = ''
  schemapattern = '^'
  system_schema = 'pg_catalog'
  system_schema_list = 'pg_catalog|pg_toast|pg_temp_[0-9]+|information_schema'
  schemapattern = $schemapattern = '^' + options.schema + '$' if options.schema

  database = Database[database_name]

  conn.exec_prepared('database', [ options.database ]).each do |row|
    database.comment = row['comment']
  end

  conn.exec_prepared('tables', [ matchpattern, system_schema_list, schemapattern ]).each do |row|
    r = OpenStruct.new(row)
    reloid = r.oid
    relname = r.tablename
    schema = database.get_schema(r.namespace)
    table = schema.get_table(relname)
    table.type = r.reltype
    table.table_description = r.table_description
    table.view_definition = r.view_definition

    acl = (r.relacl || '').gsub(/^{/,'').gsub(/}$/, '').gsub(/"/, '')
    acl.split(/\,/).each.map{ |i| i.split(/=/)}.each do |user, raw_permissions|
      user = 'PUBLIC' if user.size == 0
      if raw_permissions
	permissions, granting_user = raw_permissions.split(%r{/})
	table.set_permitions(user, raw_permissions, granting_user)
      else
	table.set_permitions(user, raw_permissions, granting_user)
      end
    end

    conn.exec_prepared('constraint', [ r.oid ]).each do |row|
      constraint = OpenStruct.new(row)
      table.add_constraint( constraint.constraint_name, constraint.constraint_source )
    end

    conn.exec_prepared('columns', [ r.oid ]).each do |row|
      column_row = OpenStruct.new(row)

      column = table.get_column(column_row.column_name)
      column.order = column_row.attnum
      column.primary_key = false
      column.fktable = false
      column.type = column_row.column_type
      column.comment = column_row.column_description
      column.default = column_row.column_default
      column.not_null = column_row.column_null == 'NOT NULL'
    end

    # Pull out both PRIMARY and UNIQUE keys based on the supplied query
    # and the relation OID.
    #
    # Since there may be multiple UNIQUE indexes on a table, we append a
    # number to the end of the the UNIQUE keyword which shows that they
    # are a part of a related definition.  I.e UNIQUE_1 goes with UNIQUE_1

    unqgroup = 0
    conn.exec_prepared('primary keys', [ r.oid ]).each do |row|
      pricols = OpenStruct.new(row)
      
      collist = pricols.constraint_definition.match(%r{\(([^)]+)\)})[1].split(/,\s*/)

      # Bump group number if there are two or more columns
      if pricols.constraint_type.to_sym == :unique and collist.size >= 2
        unqgroup += 1
      end

      collist.each do |column_name|
        column = table.get_column(column_name)
#STDERR.puts pricols.inspect
	column.add_constraint(pricols.constraint_name, pricols.constraint_type.to_sym)
      end

#puts pricols.constraint_definition
  #    puts "Primary Key: #{pricols.constraint_name}"
  #    puts "Primary Key: #{pricols.constraint_definition}"
    end

    # FOREIGN KEYS like UNIQUE indexes can appear several times in
    # a table in multi-column format. We use the same trick to
    # record a numeric association to the foreign key reference.

    # NOTE is schemapattern need hear.  We should not have iods for table in other schemas
    conn.exec_prepared('foreign keys', [ r.oid, schemapattern ]).each do |row|
      forcols = OpenStruct.new(row)

      forcols.oid
      forcols.constraint_name
      forcols.constraint_fkey
      forcols.constraint_key
      forcols.foreignrelid

      fkeyset = forcols.constraint_fkey[1..-2].split(/,\s/).map{ |i| i.to_i }
      keyset = forcols.constraint_key[1..-2].split(/,\s/).map{ |i| i.to_i }
      raise "FKEY $con Broken -- fix your PostgreSQL installation" unless fkeyset.size == keyset.size
      keylist = Array.new
      fkeylist = Array.new
      keyset.each do |k|
	row = conn.exec_prepared('foreign key arg', [ reloid, k ]).first
        keylist.push OpenStruct.new row
      end
      fkeyset.each do |k|
	row = conn.exec_prepared('foreign key arg', [ forcols.foreignrelid, k ]).first
        fkeylist.push OpenStruct.new row
      end
      fkeylist.zip(keylist).each do |list|
        fkey = list[0]
        key = list[1]
        c = database.get_column(key.namespace, key.relation_name, key.attribute_name)
        con = database.get_column(key.namespace, key.relation_name, key.attribute_name).get_constraint(forcols.constraint_name)
        con.set_fkcolumn(fkey.namespace, fkey.relation_name, fkey.attribute_name)
	con.type = :foreign_key
      end
    end

    # Pull out index information
    conn.exec_prepared('indexes', [ schema.name, table.name ]).each do |row|
      i = OpenStruct.new row
      table.add_index( i.schemaname, i.tablename, i.indexname, i.indexdef, i.definition )
    end

    # Extract Inheritance information
    conn.exec_prepared('inheritance', [ schema.name, table.name, schemapattern ]).each do |row|
      inheritance = OpenStruct.new row
      table.add_inheritance(inheritance.par_schemaname, inheritance.par_tablename, inheritance.chl_schemaname, inheritance.chl_tablename)
    end
  end

  # [ system_schema_list, schemapattern, matchpattern ]
  conn.exec_prepared('function', [ system_schema_list, schemapattern, matchpattern ]).each do |row|
    function = OpenStruct.new(row)
    function.function_args.split(' ').each do |type|
      conn.exec_prepared('function_arg', [ type ]).each do |row|
	function_args = OpenStruct.new(row)
#  puts function_args.namespace
      end
    end
  end

  # [ system_schema_list, schemapattern ]
  conn.exec_prepared('schema', [ system_schema_list, schemapattern ]).each do |row|
    schema_row = OpenStruct.new(row)
    schema = database.get_schema(schema_row.namespace)
    schema.comment = schema_row.comment
  end

end # collect database information

database_collect(options)

def get_head
  File.open('./head.html').read
end

database_name = "gam3"

require 'nokogiri'
builder = Nokogiri::HTML::Builder.new do |xml|
  xml.html {
    xml.head {
      xml.title database_name
      xml << get_head
    }
    xml.body {
      Database.each do |db|
        xml.div {
	  xml.h1 "#{db.name}"
	  db.each_schema do |schema|
	    xml.h2 "#{schema.name}"
	    schema.each_table do |table|
	      xml.hr
	      xml.a :name => table.name  # should be full name
	      xml.h3 "#{table.name}"
	      xml.table(:cellspacing => 0, :cellpadding => 3) {
	        xml.thead {
		  xml.tr {
		    xml.th 'Foreign key'
		    xml.th 'Name'
		    xml.th 'Type'
		    xml.th 'Description'
		  }
		}
		xml.tbody {
		  table.each_column do |column|
#PP.pp(column, STDERR)
		    xml.tr {
		      xml.td {
			xml.a :name => 'public.' + table.name + '.' + column.name
#			if k = column.foreign_key
			  xml.a( :href => '#' + column.foreign_key) { xml.text column.foreign_key }
#			end
		      }
		      xml.td column.name
		      xml.td column.type
		      xml.td {
		        xml.text column.description
			xml.br
			xml.text column.comment
	              }	
		    }
		  end
		}
	      }
	    end
	  end
        }
      end
    }
  }
end

puts builder.to_xml

__END__
