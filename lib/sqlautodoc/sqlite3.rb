#d
# Copyright 2014 G. Allen Morris III
#
# This file may be used under the terms of the GNU General Public
# License version 2.0 as published by the Free Software Foundation
# and appearing in the file LICENSE.GPL included in the packaging of
# this file.  Please review the following information to ensure GNU
# General Public Licensing requirements will be met:
# http://www.trolltech.com/products/qt/opensource.html
#
# This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
# WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

begin
  require "sqlite3"
rescue LoadError
  raise "you should install 'sqlite3'"
end

require 'sqlautodoc/sqlparser'

module SqlAutoDoc
  class Collect
    # A *collector* for +Sqlite3+
    class Sqlite3 < Collect
      # control the display of Sqlite3 types
      class Type < Collect::Type
        def initialize(type)
	  @original_type = type
	  if type.upcase == 'INTEGER AUTOINCRIMENT'
            @type = 'AUTOINCRIMENT'.downcase
	  else
	    @type = type.dup
	  end
	end
      end
      # Collect all the information about an Sqlite3 database
      # @param [OpenStruct] options
      def self.collect(options)
        db = SQLite3::Database.new options.database

        db.execute( "PRAGMA database_list") do |databases|
          database_name = databases[1]
          case database_name
	  when 'main'
	  else
	    next
	  end

          raise 'unkwnown' unless database_name == 'main'
          database = Database[database_name]
          database.comment = databases[2]

	  schema = database.add_schema('public')

          db.query( "select * from sqlite_master where type in ('table', 'view')") do |tables_rows|
	    tables_rows.each do |tables|
	      checks = nil
	      relname = tables[1] 

	      table = schema.add_table(relname)

	      checks = nil
	      if  tables[0] == 'table'
		checks = SqlParser.parse(tables[4])
	      else
		table.view_definition = tables[4] # the view
	      end

	      db.query( "PRAGMA table_info( #{relname} )") do |columns|
		columns.each do |column_row|
		  # ["cid", "name", "type", "notnull", "dflt_value", "pk"]
		  (cid, name, type, notnull, dflt_value, pk) = column_row
		  column = table.add_column(name)
		  column.type = Type.new(type)
		  column.set_pk if pk.to_i > 0
		  column.set_notnull if notnull.to_i != 0
		  column.set_default(dflt_value) if dflt_value
		  if checks
  #                unless checks[columns[1]].include? :exist
  #                  raise "error #{columns[1]}"
  #                end
		  end
		end
	      end
	      db.query( "PRAGMA foreign_key_list( #{relname} )") do |fks|
		fks.each do |fk|
		  (id, seq, fktable, from, to, on_update, on_delete, match) = fk

		  table.get_column(from).set_foreign_key('public', fktable, to, on_update: on_update, on_delete: on_delete, match: match)
		end
	      end
	      db.query( "PRAGMA index_list( #{tables[1]} )") do |indexes|
		indexes.each do |index_row|
		  ( seq, name, unique ) = index_row
		  index = table.add_index(name)
		  index.set_unique if unique.to_i != 0
		end
	      end
	    end
	  end
          db.query( "select * from sqlite_master where type in ('trigger')") do |triggers|
	    triggers.each do |trigger|
	      (type, name, tbl_name, rootpage, sql) = trigger
	      schema.get_table(tbl_name).add_trigger(name, sql: sql)
	    end
          end
	  database.finalize
        end
      end # def collect
    end # class Sqlite3
  end
end


