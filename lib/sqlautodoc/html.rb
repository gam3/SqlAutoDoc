

module SqlAutoDoc
  class Render
    class Html
      def self.render
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
	builder.to_xml
      end # render
    end # DocBook
  end # Render
end # SqlAutoDoc
