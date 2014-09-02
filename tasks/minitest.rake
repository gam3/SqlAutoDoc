

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.libs.push "test"
  t.test_files = FileList['test/*_test.rb', 'spec/*_spec.rb']
  t.verbose = true
end
