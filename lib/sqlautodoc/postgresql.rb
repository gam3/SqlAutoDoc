
module SqlAutoDoc
  class Collect
    class Pg < Collect
      def collect(options)
	database_name = options.database
	host = options.host
	user = options.user || ENV['USER']
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
	      column.add_constraint(pricols.constraint_name, pricols.constraint_type.to_sym)
	    end

      #puts pricols.constraint_definition
	#    puts "Primary Key: #{pricols.constraint_name}"
	#    puts "Primary Key: #{pricols.constraint_definition}"
	  end

	  # FOREIGN KEYS like UNIQUE indexes can appear several times in
	  # a table in multi-column format. We use the same trick to
	  # record a numeric association to the foreign key reference.

	  # NOTE is schemapattern needed here.  We should not have iods for table in other schemas
	  conn.exec_prepared('foreign keys', [ r.oid, schemapattern ]).each do |row|
	    forcols = OpenStruct.new(row)

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
	      table = database.get_table(fkey.namespace, fkey.relation_name)
	      column = table.get_column(fkey.attribute_name)
	      table.add_fk_ref(fkey.attribute_name, key.namespace, key.relation_name, key.attribute_name)
	      column.add_fk_ref(key.namespace, key.relation_name, key.attribute_name)
	      database.get_column(key.namespace, key.relation_name, key.attribute_name).set_fk(fkey.namespace, fkey.relation_name, fkey.attribute_name)
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
    end # class Pg
  end # class Collector
end # module SqlAutoDoc
