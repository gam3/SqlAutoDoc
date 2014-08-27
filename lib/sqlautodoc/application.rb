
require 'optparse'

module SqlAutoDoc
  class Application
    def run
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
    end

    def self.run
      application = self.new
      application.run
    end
  end
end

