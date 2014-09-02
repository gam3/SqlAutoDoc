require 'pp'
begin
  require "sqlite3"
rescue LoadError
  raise "you should install 'sqlite3'"
end
begin
  require 'sqlautodoc/sqlparser'
rescue LoadError
  raise "you should install 'sqlcreatetableparser'"
end

db = SQLite3::Database.new "test.db"

module SqlAutoDoc
  class Collect
    # A *collector* for +Sqlite+
    #
    class Sqlite3 < Collect
      # Collect all the information about an Sqlite3 database
      # @param [OpenStruct] options
      @@sqlCreateTableParser
      def self.collect(options)
        db = SQLite3::Database.new options.database

        db.execute( "PRAGMA database_list") do |databases|
          database_name = databases[1]
          raise 'unkwnow' unless database_name == 'main'
          database = Database[database_name]
          database.comment = databases[2]
          p databases[2]

          db.execute( "select * from sqlite_master where type in ('table', 'view')") do |tables|
            checks = nil
            if  tables[0] == 'table'
              checks = SqlCreateTableParser.parse tables[4]
              puts "Table: #{ tables[1] }"
            else
              puts "View: #{ tables[0] }"
              puts  tables[4] # the view
            end
            db.execute( "PRAGMA table_info( #{tables[1]} )") do |columns|
              if checks
                unless checks[columns[1]].include? :exist
                  raise "error #{columns[1]}"
                end
              end
              puts "  Collumn: #{ columns[1] }"
            end
            db.execute( "PRAGMA foreign_key_list( #{tables[1]} )") do |columns|
              puts "  FK: #{ columns[2] }"
            end
            db.execute( "PRAGMA index_list( #{tables[1]} )") do |columns|
              puts "  Index: #{ columns[1] }"
            end
            db.execute( "PRAGMA trigger_list( #{tables[1]} )") do |columns|
              puts "  Trigger: #{ columns }"
            end
          end
          db.execute( "select * from sqlite_master where type in ('trigger')") do |trigger|
            puts "  Trigger: #{ trigger }"
          end
        end
	Database.each
      end
protected
      # parse the `CREATE TABLE` code for *constraints*
      # @param [String] sql -- SQLite3 +CREATE TABLE+ Statement parser
      # @return [Hash<Hash>] one entry for each column and one entry for the table.
    end
  end
end


