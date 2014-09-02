
require 'nokogiri'

module SqlAutoDoc
  class Render
    # The Docbook class outputs DocBook xml
    class Docbook
      # Render _database_ into DocBook XML
      # @param [Database] database
      def self.render(database)
	builder = Nokogiri::XML::Builder.new do |xml|
	  xml.doc.create_internal_subset(
	    'book',
	    "-//OASIS//DTD DocBook V5.0//EN",
	    "http://docbook.org/xml/5.0/dtd/docbook.dtd")

	  xml.book(:id => 'database.' + database.name, :xreflabel => database.name + ' database schema') {
	    xml.title database.title
	    database.each_schema do |schema|
	      xml.chapter(:id => schema.name + '.schema', :xreflabel => schema.name) {
		xml.title "Schema " + schema.name
		xml.para schema.description
		schema.each_table do |table|
		  xml.section(:id => table.dbid, :xreflabel => table.schema_name) {
		    xml.title(:id=>"#{table.dbid}-title") { 
		      xml.text "\n   Table: \n\n   "
		      xml.structname table.name
		      xml.text "\n    "
		    }
		    xml.para {
		      xml.variablelist {
			xml.title {
			  xml.text "\n Structure of "
			  xml.structname table.name
			  xml.text "\n   "
			}
			table.each_column do |column|
			  xml.varlistentry {
			    xml.term {
			      xml.structfield(column.name || 'bob')
			    }
			    xml.listitem {
			      xml.para {
				xml.type    column.type
				column.description_each do |x|
				  xml.literal x
				end
				if column.references?
				  xml.literal "REFERENCES"
				  xml.xref :linkend => column.dbref
				end
				if column.default?
				  xml.literal column.default
				end
			      }
			      if c = column.comment
				xml.para c
			      end
			    }
			  }
			end
		      }
		      if table.view?
			xml.figure {
			  xml.title "Definition of view " + table.name
			  xml.programlisting {
			    xml.text table.view
			  }
			}
		      end
		      if table.contraints?
			xml.variablelist {
			  xml.title "Constraints on #{table.name}"
			  table.each_contraint do |key, value|
			    xml.varlistentry {
			      xml.term key
			      xml.listitem {
				xml.para value
			      }
			    }
			  end
			}
		      end
		      if table.indexes?
			xml.variablelist {
			  xml.title "Indexes on #{table.name}"
			  table.each_index do |key, value|
			    xml.varlistentry {
			      xml.term key
			      xml.listitem {
				xml.para value
			      }
			    }
			  end
			}
		      if table.inherits?
		      end
		      if table.inherited?
		      end
		      end
		      if table.fk_refs?
			xml.itemizedlist {
			  xml.title "Tables referencing #{table.name} via Foreign Key Constraints"
			  table.referenced_by_foreign_key_each do |fk|
			    xml.listitem {
			      xml.para {
				xml.xref :linkend => fk
			      }
			    }
			  end
			}
		      end
		    }
		  }
		end
	      }
	    end
	  }
	end
	File.open("#{database.name}.sgml", 'w:utf-8') do |file|
	  file.print builder.to_xml
	end
      end
    end
  end
end

