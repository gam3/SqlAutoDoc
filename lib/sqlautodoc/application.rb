#
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

require 'optparse'
require 'ostruct'
require 'sqlautodoc'
require 'sqlautodoc/version'

module SqlAutoDoc
  # A Class to allow CLI access to SqlAutoDoc
  class Application
    # Run the application
    # @return [true, false]
    def run
      @options = options = OpenStruct.new
      OptionParser.new do |opts|
	opts.banner = "Usage: #{File.basename($0)} [options]"
	opts.separator ""
	opts.separator "Specific options:"
	opts.on("-c", "--collector dbtyep", String, "Specify the database type [pq, sqlite, mysql]") do |value|
	  case value
	  when /^s/
	    value = 'sqlite3'
	  when /^p/
	    value = 'pg'
	  when /^m/
	    value = 'mysql'
	  else
	    raise "Unknown database type #{value}"
	  end
	  options.database_type = value
	end
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
	  puts <<-EOF
sqlautodoc #{SqlAutoDoc::VERSION::STRING}
Copyright (C) 2014 G. Allen Morris III
License GPLv2: GNU GPL version 2 or later <http://www.gnu.org/licenses/gpl-2.0.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by G. Allen Morris III
          EOF
	  exit
	end
      end.parse!

      unless options.database_type
        if options.database.match(/\.db$/)
	  options.database_type = :sqlite3
	else
	  options.database_type = :pg
	end
        
      end
      case options.database_type.to_sym
      when :sqlite3
	require 'sqlautodoc/sqlite3'
	data = Collect::Sqlite3.collect(options)
      when :pg
	require 'sqlautodoc/postgresql'
	data = Collect::Pg.collect(options)
      else
        raise "unsupported database type #{options.database_type}"
      end

      begin
	require 'sqlautodoc/html'
	Render::Html.render
      rescue => error
        puts "HTML #{error}"
	puts error.backtrace
      end
      begin
	require 'sqlautodoc/docbook'
	Render::Docbook.render(Database.first)
      rescue => error
        puts "Docbook #{error}"
      end
      true
    end
    # run the application
    # @return [true, false]
    def self.run
      application = self.new
      application.run
    end
  end
end

