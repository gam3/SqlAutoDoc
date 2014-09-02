
module SqlAutoDoc
  class Render
    # Render to HTML
    class Html
      # Get extra xml for inside the head element
      # @return [String]
      def self.get_head
        ret = <<-XML
  <link rel="stylesheet" href="css/style.css" type="text/css" charset="utf-8" />
  <link rel="stylesheet" href="css/common.css" type="text/css" charset="utf-8" />
  <script type="text/javascript" charset="utf-8">
    hasFrames = window.top.frames.main ? true : false;
    relpath = '';
    framesUrl = "frames.html#!" + escape(window.location.href);
  </script>
  <script type="text/javascript" charset="utf-8" src="js/jquery.js"></script>
  <script type="text/javascript" charset="utf-8" src="js/app.js"></script>
        XML
        ret
      end
      # get HTML describing the database
      def self.render
        require 'nokogiri'

        Database.each do |db|
          builder = Nokogiri::HTML::Builder.new do |xml|
            xml.html {
              xml.head {
                xml.title db.name
                xml << get_head
              }
              xml.body {
                xml.div {
                  xml.h1 "#{db.name}"
                  db.each_schema do |schema|
                    xml.h2 "#{schema.name}"
                    schema.each_table do |table|
                      xml.hr
                      xml.a :name => table.name   # set Anchor for table
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
                                if column.foreign_key?
                                  xml.a( :href => column.foreign_key.local_anchor) { xml.text column.foreign_key.local }
                                end
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
                      if table.trigger?
			xml.text 'Triggers:'
			table.each_trigger do |trigger|
			  xml.ul {
			    xml.li { xml.text(trigger.name) }
			  }
			end
		      end
                      if table.referenced_by_foreign_key?
                        xml.text 'Tables referencing this one via Foreign Key Constraints:'
                        xml.ul {
                          table.referenced_by_foreign_key_each do |key|
                            xml.li { xml.a( :href => key.anchor) { xml.text key.name } }
                          end
                        }
                      end
                    end
                  end
                }
              }
            }
          end
          File.open("#{db.name}.html", 'w:utf-8') do |file|
            file.print builder.to_xml
          end
        end
      end # render
    end # DocBook
  end # Render
end # SqlAutoDoc
