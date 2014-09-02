def init
  super
  sections.place(:tag_list).after_any(:files)
end

def menu_lists
  super + [{:type => 'collector', :title => 'Collector', :search_title => 'Collector'}]
end
