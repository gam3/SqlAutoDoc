def generate_collector_list
  @list_title = "Collector Methods"
  @list_type = "methods"
  asset('collector_method_list.html', erb(:full_list))
end

