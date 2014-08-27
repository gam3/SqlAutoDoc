
# @author "G. Allen Morris III" <gam3@gam3.net>
# Collect information about a database and render it to different
# text and graphical forms.
module SqlAutoDoc
  class Database
    @@databases = Hash.new{ |h, k| h[k] = Database.new(k) }
    attr_accessor :comment
    def self.[](x)
      @@databases[x]
    end
    def self.all
      @@databases
    end
    def self.each
      @@databases.each do |k, v|
	yield v
      end
    end
    attr_accessor :name
    attr_accessor :comment
    def initialize(n)
      @name = n
      @schemas = Hash.new{ |h, k| h[k] = Schema.new(k, n) }
    end
    def title
      @name + ' Model'
    end
    def get_schema(name)
      @schemas[name]
    end
    def get_table(name, table_name)
      @schemas[name].get_table(table_name)
    end
    def get_column(name, table_name, column_name)
      @schemas[name].get_table(table_name).get_column(column_name)
    end
    def each_schema
      @schemas.each do |n, v|
	yield v
      end
    end
    class Schema
      attr_accessor :comment
      attr_reader :name
      def initialize(n, database)
	@name = n
	@database = database
	@tables = Hash.new{ |h, k| h[k] = Table.new(k, n, @database) }
      end
      def get_column(table_name, column_name)
	@tables[table_name].get_column(column_name)
      end
      def get_table(name)
	unless @tables[name].schema
  raise "error"
	end
	@tables[name]
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
      class Table
	class Column
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
	    def set_fkcolumn(schema, table, column)
	      @schema = schema
	      @table = table
	      @column = column
	      @fk = true
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
	  def default
	    "DEFAULT #{@default}"
	  end
	  def default?
	    !@default.nil?
	  end
	  def initialize(name)
	    @name = name
	    @constraints = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	    @indexes = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	    @inherits = Hash.new{ |h, k| h[k] = Constraint.new(k) }
	    @description = Array.new
	    @fk_refs = Array.new
	  end
	  def add_fk_ref(a, b, c)
	    @fk_refs.push [a, b, c]
	  end
	  def set_fk(a, b, c)
	    @fktable = [a, b, c].join('.')
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
	  def foreign_key
	    ret = Array.new
	    @constraints.each do |k, v|
	      if v.type == :foreign_key
		ret.push [v.schema, v.table, v.column].join('.')
	      end
	    end
	    ret.join(', ')
	  end
	  def dbref
	    data = @fktable.split('.')
	    "#{data[0]}.table.#{data[1]}".gsub(/_/, '-')
	  end
	  def references?
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
	  def description
	    ret = @description
	    if @not_null && !@primary_key
	      ret += ' NOT NULL'
	    end
	    ret
	  end
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
	def initialize(name, schema, database)
	  @name = name
	  @schema = schema
	  @database = database
	  @columns = Hash.new{ |h, k| h[k] = Column.new(k) }
	  @users = Hash.new{ |h, k| h[k] = User.new(k) }
	  @inherite_from = Array.new
	  @inherited_by = Array.new
	  @indexes = Array.new
	  @contraint = Hash.new
	  @dbid = "#{schema}.table.#{name}".gsub(/_/, '-')
	  @schema_name = "#{schema}.#{name}"
	  @fk_refs = Array.new
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
	  Database[@database].get_schema(schema).get_table(table).add_inherited_by(@schema, @name)
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
	def add_index(schema, table, index, indexdef, definition)
	  @indexes.push [ schema, table, index, indexdef, definition ]
	end
	def get_column(name)
	  column = @columns[name]
	end
	def each_column
	  @columns.values.sort{ |a, b| a.order <=> b.order }.each do |v|
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
	  @fk_refs.each do |x|
	    y = [x[:ref][0], 'table', x[:ref][1]].join('.').gsub(/_/, '-')
	    yield y
	  end
	end
	def title
	  "#{self}#{'title'}"
	end
      end # class Table
    end # class Schema
  end # class Database
end # SqlAutoDoc

