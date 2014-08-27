lib_dir = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$:.unshift(lib_dir)
$:.uniq!

#require 'rubygems'
require 'rake'

require File.join(File.dirname(__FILE__), 'lib/sqlautodoc', 'version')

PKG_DISPLAY_NAME   = 'SqlAutoDoc'
PKG_NAME           = PKG_DISPLAY_NAME.downcase
PKG_VERSION        = SqlAutoDoc::VERSION::STRING

RUBY_FORGE_PROJECT = PKG_NAME
RUBY_FORGE_USER    = 'gam3'
RUBY_FORGE_PATH    = "/var/www/gforge-projects/#{RUBY_FORGE_PROJECT}"
RUBY_FORGE_URL     = "http://#{RUBY_FORGE_PROJECT}.rubyforge.org/"

PKG_AUTHOR         = 'G. Allen Morris III'
PKG_AUTHOR_EMAIL   = 'gam3@gam3.net'
PKG_HOMEPAGE       = RUBY_FORGE_URL
PKG_SUMMARY        = 'A parsing system based on JSON Schema.'
PKG_DESCRIPTION    = <<-TEXT
An implementation of the JSON Schema specification. Provides automatic parsing
for any given JSON Schema.
TEXT

PKG_FILES = FileList[
    'lib/**/*', 'spec/**/*', 'vendor/**/*',
    'test/**/*', 'tasks/**/*', 'bin/**/*',
    '[A-Z]*', 'Rakefile'
].exclude(/[_\.]git$/)

task :default => 'test'

Dir['tasks/**/*.rake'].each { |rake| load rake }


