
require File.expand_path('../lib/sqlautodoc/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "sqlautodoc"
  s.summary       = "Documentation tool for SQL databases"
  s.description   = <<-eof
    SqlAutoDoc is a documentation generation tool for many SQL databases.
    It enables the user to generate consistent, usable documentation that can be
    exported to a number of formats very easily, and also supports extending for
    custom databases or output formats.
  eof
  s.version       = SqlAutoDoc::VERSION::STRING
  s.date          = Time.now.strftime('%Y-%m-%d')
  s.author        = "G. Allen Morris III"
  s.email         = "gam3@gam3.net"
  s.homepage      = "http://sqlautodoc.gam3.net"
  s.platform      = Gem::Platform::RUBY
  s.files         = Dir.glob("{docs,bin,lib,spec,tasks,templates,benchmarks}/**/*") +
                    ['LICENSE', 'README.md', 'Rakefile', '.yardopts', __FILE__]
  s.require_paths = ['lib']
  s.executables   = ['sqlautodoc']
  s.has_rdoc      = 'sqlautodoc'
  s.rubyforge_project = 'sqlautodoc'
  s.license = 'GPL-2.0' if s.respond_to?(:license=)
end

