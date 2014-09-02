require 'rake'

begin
  require 'yard'
  require 'yard/rake/yardoc_task'

  namespace :doc do
    desc 'Generate Yardoc documentation'
    YARD::Rake::YardocTask.new do |yardoc|
      yardoc.name = 'yard'
      yardoc.options = ['--verbose']
      yardoc.files = [
        '--proteced', '--no-private',
        'lib/**/*.rb', 'bin/**/*', 'spec/**/*', '-', 'README.md', 'CHANGELOG.md', 'LICENSE', 'docs/*.md', 'docs/sqlautodoc.rb'
      ]
    end
  end

  task 'clobber' => ['doc:clobber_yard']

  desc 'Alias to doc:yard'
  task 'doc' => 'doc:yard'
rescue LoadError
  # If yard isn't available, it's not the end of the world
  desc 'Alias to doc:rdoc'
  task 'doc' => 'doc:rdoc'
end

__END__

--protected
--no-private
--exclude /server/templates/
--asset docs/images:images
-
