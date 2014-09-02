
require 'mysql'

module SqlAutoDoc
  class Collect
    # A *collector* for +MySQL+
    class MySQL < Collect
      # Collect all the information about an Sqlite3 database
      # @param [OpenStruct] options
      def self.collect(options)
      end
    end
  end
end
