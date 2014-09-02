#
# Copyright 2014 G. Allen Morris III
#
# This file may be used under the terms of the GNU General Public
# License version 2.0 as published by the Free Software Foundation
# and appearing in the file LICENSE.GPL included in the packaging of
# this file.  Please review the following information to ensure GNU
# General Public Licensing requirements will be met:
# http://www.trolltech.com/products/qt/opensource.html
#
# This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
# WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

require 'set'

# @author "G. Allen Morris III" <gam3@gam3.net>
# Collect information about a database and render it to different
# text and graphical forms.
module SqlAutoDoc
  # The Database class is used as a Singleton
  # This means that there can only be only one Database
  # with a particualar name.
  # Each unique Database object then contains a set of 
  # database Scheme.
  class Database
    # This Hash contains each database indexed by name
    @@databases = Hash.new{ |h, k| h[k] = Database.new(k) }
    # @param [String] database_name The name of the database
    def self.get_database(database_name)
      raise ArgumentError unless @@databases.include? database_name
      @@databases[database_name]
    end
    # get a particular database by name
    def self.[](database_name)
      @@databases[database_name]
    end
    # @return [Hash] The hash of all databases.
    def self.all
      @@databases
    end
    # iterate over each database
    def self.each
      @@databases.each do |k, v|
	yield v
      end
    end
    # @!group Render Attribute Summary
    # The unique name of the database.
    attr_accessor :name
    # The comment (if there is one) describing the database.
    attr_accessor :comment
    # @!endgroup
    # @!group Render Method Summary
    def title
      @name
    end
    # iterate over each schema in a database
    def each_schema
      @schemas.each do |n, v|
	yield v
      end
    end
    # @!endgroup
    def initialize(n)
      @name = n
      @schemas = Hash.new{ |h, k| h[k] = Schema.new(k, n) }
    end
    def title
      @name + ' Model'
    end
    def self.first
      @@databases[@@databases.keys.first]
    end
    # Add or get a schema from the database
    # @param [String] schema_name The name of the schema
    # @return [Schema] the named schema
    def add_schema(schema_name)
      @schemas[schema_name]
    end
    # Get a schema from the database
    # @param [String] schema_name The name of the schema
    # @return [Schema] the named schema
    # @raise [ArgumentError] if schema does not exist
    def get_schema(schema_name)
      raise ArgumentError.new(name) unless @schemas.include? schema_name
      @schemas[schema_name]
    end
    # Get a table from a schema
    def get_table(name, table_name)
      get_schema(name).get_table(table_name)
    end
    # get_column a column from the database
    # @param [String] schema_name -- Schema name
    # @param [String] table_name -- Table name
    # @param [String] column_name -- Column name
    # @return [Column]
    # @raise [ArgumentError] if column does not exist
    def get_column(schema_name, table_name, column_name)
      @schemas[schema_name].get_table(table_name).get_column(column_name)
    end
    # There is a single Schema class for each Schema in each database
    class Schema
      attr_accessor :comment
      attr_reader :name
      def initialize(name, database)
	@name = name
	@database = database
	@tables = Hash.new{ |h, k| h[k] = Table.new(k, name, @database) }
      end
      # Get a column from the schema
      # @param [String] table_name -- Table name
      # @param [String] column_name -- Column name
      # @return [Column]
      # @raise [ArgumentError] if column does not exist
      def get_column(table_name, column_name)
	get_table(table_name).get_column(column_name)
      end
      # Get a table to the schema
      # @param [String] table_name -- Table name
      # @return [Table]
      # @raise [ArgumentError] if column does not exist
      def add_table(table_name)
	@tables[table_name]
      end
      # Get a table to the schema
      # @param [String] table_name -- Table name
      # @return [Table]
      # @raise [ArgumentError] if column does not exist
      def get_table(table_name)
	raise ArgumentError unless @tables.include? table_name
	@tables[table_name]
      end
      def each_table
	@tables.each_value.sort{ |a, b| a.name <=> b.name }.each do |n|
	  yield n
	end
      end
      def title
	'Schema#title'
      end
      # get each line of description
      def description
	@comment
      end
      # Each table is represented by a Table object
      class Table
        # tables have Indexs
	class Index
	  def initialize(name, args ={})
	    @name = name
	    @args = args
	    @unique = nil
	  end
	  def set_unique(state = true)
	    @unique = state
	  end
	end
        # ForeignKey are a relationship between to tables
	# or at least a set of columns and an index
	class ForeignKey
	  def initialize(fschema, ftable, fcolumn, to_schema, to_table, to_column, args = {} )
	    (@from_schema, @from_table, @from_column, @to_schema, @to_table, @to_column, @args) = [fschema, ftable, fcolumn, to_schema, to_table, to_column, args]
	  end
	  def name
	    "#{@to_table}"
	  end
	  def anchor
	    "##{@to_table}"
	  end
	  def local
	    "#{@from_table}.#{@from_column}"
	  end
	  def local_anchor
	    "#" + [ @from_schema, @from_table, @from_column].join('.')
	  end
	end
	# A Trigger object holds information about triggers
	class Trigger
	  # @param [String] trigger_name
	  # @param [Hash] args
	  # @option args :bob don't know yet
	  def initialize(trigger_name, args = {})
	    @name = trigger_name
	    @args = args
	  end
	  def name
	    @name
	  end
	end
	# Each column in a tables is represented by a Column object
	class Column
	  # @todo it is not clear if Constraints should be on tables of Columns
	  class Constraint
	    attr_reader :name
	    attr_accessor :type
	    attr_accessor :schema
	    attr_accessor :table
	    attr_accessor :column
	    attr_accessor :schema
	    def initialize(name)
	      @name = name
	    end
	  end
	  attr_reader :name
	  attr_accessor :order
	  attr_accessor :primary_key
	  attr_accessor :fktable
	  attr_accessor :type
	  attr_accessor :comment
	  attr_accessor :not_null
	  attr_writer :default
	  def initialize(name, table_name, schema_name, database_name)
	    @name = name
	    @database_name = database_name
	    @schema_name = schema_name
	    @table_name = table_name
	    Database.get_database(database_name).get_schema(schema_name).get_table(table_name);

	    @constraints = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	    @indexes = Hash.new
	    @inherits = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	    @description = Array.new
	    @fk_refs = Array.new
	  end
	  def default
	    "DEFAULT #{@default}"
	  end
	  def default?
	    !@default.nil?
	  end
	  def set_pk
	    @pk = true
	  end
	  def set_notnull
	    @notnull = true
	  end
	  def set_default(default_value)
	    @default_value = default_value
	  end
	  def finalize_foreign_key_reference
	    Database.get_database(@database_name).get_schema(@fk_schema).get_table(@fk_table).add_referenced_by_foreign_key(@fk)
	  end
	  def add_fk_ref(a, b, c)
	    @fk_refs.push [a, b, c]
	  end
	  def set_foreign_key(schema, table, column, args = {})
	    @fk = ForeignKey.new(schema, table, column, @schema_name, @table_name, @name, args)
	    @fk_schema = schema
	    @fk_table = table
	    @fk_column = column
	    @fk_args = args
	  end
	  def add_constraint(name, definition)
	    case definition
	    when :unique
	      @unique = true
	      @description << 'UNIQUE'
	    when :primary_key
	      @primary_key = true
	      @description << 'PRIMARY KEY'
	    else
	      raise definition.to_s
	    end
	    @constraints[name].type = definition || 'none'
	    @constraints[name]
	  end
	  def get_constraint(name)
	    @constraints[name]
	  end
	  def each_constraint
	    @constraints.each do |k, v|
	      yield v
	    end
	  end
	  # does this table 
	  def foreign_key?
	    @fk
	  end
	  def foreign_key
	    @fk
	  end
	  def references?
raise 'references'
	    @fktable
	  end
	  def description_each
	    temp = @description.dup
	    if @not_null && !@primary_key
	      temp << 'NOT NULL'
	    end
	    temp.each do |x|
	      yield x
	    end
	  end
	  # Column Description
	  def description
	    ret = @description.to_set
	    if @pk
	      ret.add 'PRIMARY KEY'
	    else  
	      ret.add 'UNIQUE' if @unique
	      ret.add 'NOT NULL' if @notnull
	    end
	    if @default_value
	      ret.add "DEFAULT #{@default_value}"
	    end
	    if @not_null && !@primary_key
	      ret << ' NOT NULL'
	    end
	    ret.to_a.join(' ')
	  end
	  # 
	  def indexes?
	    @indexes.size > 0
	  end
	  def each_index
	    @indexes.each do |k, v|
	      yield v
	    end
	  end
	  def inherit?
	    @inherits.size > 0
	  end
	  def each_inherit
	    @inherits.each do |k, v|
	      yield v
	    end
	  end
	end
	# Informaation about users is kept in a User Object
	class User
	  attr_accessor :granted_by
	  attr_accessor :raw_permissions
	  def initialize(name)
	    @name
	  end
	end
	attr_reader :name
	attr_accessor :type
	attr_accessor :table_description
	attr_accessor :view_definition
	attr_accessor :schema
	attr_accessor :dbid
	attr_accessor :schema_name
	# Table
	def initialize(name, schema, database)
	  @name = name
	  @schema = schema
	  @database = database
	  @columns = Hash.new{ |h, k| h[k] = Column.new(k, @name, @schema, @database) }
	  @users = Hash.new{ |h, k| h[k] = User.new(k) }
	  @inherite_from = Array.new
	  @inherited_by = Array.new
	  @indexes = Hash.new
	  @contraint = Hash.new
	  @dbid = "#{schema}.table.#{name}".gsub(/_/, '-')
	  @schema_name = "#{schema}.#{name}"
	  @fk_refs = Array.new
	  @triggers = Hash.new{ |h, k| h[k] = Trigger.new(k) }
	end
	# Add a trigger to a table
	def trigger?
	  @triggers.size > 0
	end
	def each_trigger
	  @triggers.each_value do |x|
	    yield x
	  end
	end
        def add_trigger( trigger, args = {})
	  @triggers[trigger] = Trigger.new(trigger, args)
	end
	def add_fk_ref(column, a, b, c)
	  @fk_refs.push Hash[:column => column, :ref => [a, b, c]]
	end
	def set_permitions(a, b, c)
	  user = @users[a]
	  user.granted_by = c
	  user.raw_permissions = b
	end
	def add_inherited_by(schema, table)
	  @inherited_by.push [schema, table]
	end
	def add_inheritance(schema, table, cs, ct)
	  @inherite_from.push [schema, table]
	  Database.get_database(@database).get_schema(schema).get_table(table).add_inherited_by(@schema, @name)
	end
	def inherits?
	  @inherite_from.size > 0
	end
	def inherited?
	  @inherited_by.size > 0
	end
	def each_inherit
	  @inherite_from.each do |k, v|
	    yield v
	  end
	end
	# 
	def add_index(index_name, args = {})
	  @indexes[index_name] = Index.new(index_name, args)
	end
	# Add a column to the table
	# @param [String] column_name Column name
	# @param [Hash] args
	# @option args [Type] :type
	# @return [Column] the Column object
	# @raise [ArgumentError] if column does not exist
	def add_column(column_name, args = {})
	  column = @columns[column_name]
	end
	# Get a column from the table
	# @param [String] column_name Column name
	# @return [Column] The requested column
	# @raise [ArgumentError] if column does not exist
	def get_column(column_name)
	  raise ArgumentError unless @columns.include? column_name
	  column = @columns[column_name]
	end
	def each_column
#	  @columns.values.sort{ |a, b| a.order <=> b.order }.each do |v|
	  @columns.each_value do |v|
	    yield v
	  end
	end
	def add_constraint(name, definition)
	  @contraint[name] = definition
	end
	def view?
	  @view_definition
	end
	def view
	  @view_definition
	end
	def contraints?
	  @contraint.keys.size > 0
	end
	def each_contraint
	  @contraint.each do |k, v|
	    yield k, v
	  end
	end
	def indexes?
	  @indexes.size > 0
	end
	def each_index
	  @indexes.each do |k, v|
	    yield k, v
	  end
	end
	def fk_refs?
	  @fk_refs.size > 0
	end
	def each_fk
raise "OBSOLETE"
	  @fk_refs.each do |x|
	    y = [x[:ref][0], 'table', x[:ref][1]].join('.').gsub(/_/, '-')
	    yield y
	  end
	end
	def title
	  "#{self}#{'title'}"
	end
	def referenced_by_foreign_key?
#puts "asdfasdfsdf #{@fk_refs} #{@name}"
	  @fk_refs.size > 0
	end
	# 
	def referenced_by_foreign_key_each
	  @fk_refs.each do |fk|
	    yield fk
	  end
	end
	def add_referenced_by_foreign_key(fk)
	  @fk_refs.push fk 
	end
      end # class Table
    end # class Schema
    def finalize
      each_schema do |schema|
	schema.each_table do |table|
	  table.each_column do |column|
	    if column.foreign_key?
	      column.finalize_foreign_key_reference
	    end
	  end
	end
      end
      each_schema do |schema|
	schema.each_table do |table|
	  table.each_column do |column|
	    column.freeze
	  end
	  table.freeze
	end
	schema.freeze
      end
      self.freeze
    end # finalize
  end # class Database
  # All or the Renders live under this class
  class Render
  end
  # All of the Collectors live under this class
  class Collect
    # Class to Render types
    class Type
      def initialize(type)
	@type = type
      end
      # @private
      def to_s
        @type
      end
    end
  end
end # SqlAutoDoc

