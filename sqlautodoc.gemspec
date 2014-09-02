# -*- encoding: utf-8 -*-
# stub: sqlautodoc 0.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "sqlautodoc"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["G. Allen Morris III"]
  s.date = "2014-09-02"
  s.description = "An implementation of the JSON Schema specification. Provides automatic parsing\nfor any given JSON Schema.\n"
  s.email = "gam3@gam3.net"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["CHANGELOG.md", "LICENSE", "README.md", "Rakefile", "bin/sqlautodoc", "lib/sqlautodoc", "lib/sqlautodoc.rb", "lib/sqlautodoc/application.rb", "lib/sqlautodoc/docbook.rb", "lib/sqlautodoc/html.rb", "lib/sqlautodoc/mysql.rb", "lib/sqlautodoc/postgresql.rb", "lib/sqlautodoc/sqlite3.rb", "lib/sqlautodoc/sqlparser.rb", "lib/sqlautodoc/version.rb", "spec/database_spec.rb", "tasks/clobber.rake", "tasks/gem.rake", "tasks/git.rake", "tasks/metrics.rake", "tasks/minitest.rake", "tasks/rdoc.rake", "tasks/yard.rake", "test/data", "test/data/postgresql.sql", "test/data/sqlite.sql", "test/data/test.db", "test/test_helper.rb"]
  s.homepage = "http://sqlautodoc.rubyforge.org/"
  s.licenses = ["GPL-2.0"]
  s.rdoc_options = ["--main", "README.md"]
  s.rubyforge_project = "sqlautodoc"
  s.rubygems_version = "2.4.1"
  s.summary = "A parsing system based on JSON Schema."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.9.0", "~> 0.9"])
    else
      s.add_dependency(%q<rake>, [">= 0.9.0", "~> 0.9"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.9.0", "~> 0.9"])
  end
end
