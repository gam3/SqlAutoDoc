require 'set'

require 'pp'

module SqlAutoDoc
  # parse sql needed for get some information out of some databases
  # This parser is very incomplete as it currently only needs to be
  # able to return +CHECK+ constraints
  class SqlParser
    # @private
    UNKNOWN = :unknown
    # @private
    UNIQUE = :unique
    # @private
    PRIMARY_KEY = :primary_key
    # Parsing errors return an object of this class
    class ParseError < StandardError
    end
    # parse the `CREATE TABLE` code for *constraints*
    # @param [String] sql -- SQLite3 +CREATE TABLE+ Statement parser
    # @return [Hash<Hash>] one entry for each column and one entry for the table.
    def self.parse(sql)
      self.new(sql).table_definition
    end
    # the SQL is broken down into tokens that are stored in this class
    class Token
      # the value of the token
      attr_accessor :value
      # the type of the token
      attr_accessor :type
    end
    # Lexer of SQL Tokens
    class Lexer
      # regular expersion to match Database Identifiers
      @@ident = Regexp.new('\A(?:' + ['(?:[_[[:alpha:]]][_$[[:alnum:]]]*)', '(?:"(?:[^"]|"")*")' ].join('|') + ')')
      def initialize(str)
	@input = str
	@return_previous_token = false
      end
      # return the next token from the input
      def get_next_token
	if @return_previous_token
	  @return_previous_token = false
	  return @previous_token
	end

	token = Token.new

	raise ArgumentError.new('lexer error') if @input.nil?
	@input.lstrip!
	case @input
	when ''
	  token.type = :end
	when /\A\(/
	  token.type = :lparen
	  token.value = $~
	when /\A,/
	  token.type = :comma
	when /\A\)/
	  token.type = :rparen
	  token.value = $~
	when /\A\./
	  token.type = :dot
	when /\A>/
	  token.type = :greater_than
	  token.value = $~
	when /\A</
	  token.type = :less_than
	  token.value = $~
	when /\ACHECK\b/i
	  token.type = :check
	  token.value = $~
	when /\ACOMMIT\b/i
	  token.type = :commit
	when /\AUNIQUE\b/i
	  token.type = :unique
	when /\AON UPDATE\b/i
	  token.type = :on_update
	when /\AON DELETE\b/i
	  token.type = :on_delete
	when /\ACASCADE\b/i
	  token.type = :cascade
	when /\ASET NULL\b/i
	  token.type = :set_null
	when /\ASET DEFAULT\b/i
	  token.type = :set_default
	when /\ARESTRICT\b/i
	  token.type = :restrict
	when /\ANO ACTION\b/i
	  token.type = :no_action
	when /\AAUTO_INCRIMENT\b/i
	  token.type = :autoincriment
	when /\AAUTOINCRIMENT\b/i
	  token.type = :autoincriment
	when /\ADEFAULT\b/i
	  token.type = :default
	when /\ANOT\b/i
	  token.type = :not
	when /\ANULL\b/i
	  token.type = :null
	when /\APRIMARY\s+KEY\b/i
	  token.type = :primary_key
	when /\ACREATE\b/i
	  token.type = :create
	when /\ACONSTRAINT\b/i
	  token.type = :constraint
	when /\AFOREIGN KEY\b/i
	  token.type = :foreign_key
	when /\AREFERENCES\b/i
	  token.type = :references
	when /\ATABLE\b/i
	  token.type = :table
	when /\ATEMP\b/i
	  token.type = :temporary
	when /\ATEMPORARY\b/i
	  token.type = :temporary
	when /\AON\b/i
	  token.type = :on
	when /\A[0-9]+\b/
	  token.type = :number
	  token.value = $~
        # this must be after all resevered words
	when @@ident
	  token.type = :ident
	  token.value = $~
	when /\A'[^']*'/
	  token.type = :literal
	  token.value = $~
	else
	  raise "unknown token '#{@input}'"
	end
	@input = $'
	@input.lstrip! if @input

	@previous_token = token
	token
      end
      # push the previous token back on the stack of tokens
      # @todo
      # @return [nil]
      def revert
	raise 'only call revert once' if @return_previous_token
	@return_previous_token = true
      end
    end
    def initialize(sql = 'create table allen (id integer, name text(10))')
      @sql = sql
      @lexer = Lexer.new(@sql)
      @collect_search = Array.new
      @checks = Array.new
    end
    # get a token of a known type
    # @param [Sym] type -- The token type
    # @return [Token, nil]
    def get_token(type)
      t1 = @lexer.get_next_token
      if t1.type == type
	return t1
      else
	@lexer.revert
	return nil
      end
    end
    # get the scope of a table
    # <table scope>    ::=   <global or local> TEMPORARY
    def table_scope
      if cn = get_token(:temporary)
      end
    end
    # get the name of the table
    def table_name
      t1 = @lexer.get_next_token
      raise unless t1.type == :ident
    end

    # <table element> http://savage.net.au/SQL/sql-2003-2.bnf.html#xref-table element
    def table_element
      column_definition || table_constraint_definition
    end

    # get a list of column names
    #
    #     <column name list> ::= <column name> [ { <comma> <column name> }... ]
    def column_name_list
      if cn = get_token(:ident)
        while get_token(:comma)
          cn = get_token(:ident)
        end
      end
    end

    def constraint_characteristics

    end

    def contraint_name_definition
      if cn = (get_token(:contraint))
        if cn = (get_token(:ident))
        end
      end
    end
    
    def unique_constraint_definition
      if cn = (get_token(:primary_key) || get_token(:unique_key))
        get_token(:lparen)
        column_name_list
        get_token(:rparen)
        true
      else
        false
      end
    end

    def search_condition
      while t = @lexer.get_next_token
        if t.type == :rparen
	  @checks << @collect_search.join(' ')
	  @lexer.revert
	  break
	end
	@collect_search << t.value
      end
    end

    def check_constraint_definition
       if get_token(:check)
         get_token(:lparen)
	 search_condition
	 get_token(:rparen)
       end
    end

    # table constraint
    #
    # <table constraint>    ::= 
    #        <unique constraint definition>
    #	   | <referential constraint definition>
    #	   | <check constraint definition>
    def table_constraint
      unique_constraint_definition || referential_constraint_definition || check_constraint_definition
    end

    # the list of referenced columns
    def referenced_column_list
      column_name_list
    end
    # stuff
    def referencing_columns
      referenced_column_list
    end

    def update_delete_rule
      if get_token(:on_delete) || get_token(:on_update)
	get_token(:cascade) or get_token(:set_null) or get_token(:set_default) or get_token(:restrict) or get_token(:no_action)
      else
        nil
      end
    end

    def referential_triggered_action
      update_delete_rule
      update_delete_rule
    end

    # <referenced table and columns>    ::=   <table name> [ <left paren> <reference column list> <right paren> ]
    def referenced_table_and_columns
       get_token(:ident)
       get_token(:lparen)
       referencing_columns
       get_token(:rparen)
    end

    # <references specification>    ::=   REFERENCES <referenced table and columns> [ MATCH <match type> ] [ <referential triggered action> ]
    def references_specification
      if get_token(:references)
	referenced_table_and_columns
	referential_triggered_action
	true
      else
        nil
      end
    end

    # <referential constraint definition>    ::=   FOREIGN KEY <left paren> <referencing columns> <right paren> <references specification>
    def referential_constraint_definition
      if get_token(:foreign_key)
	get_token(:lparen)
	referencing_columns
	get_token(:rparen)
	references_specification
	return true
      end
      nil
    end

    # <table constraint definition>    ::=   [ <constraint name definition> ] <table constraint> [ <constraint characteristics> ]
    # @todo save the state befor _contraint_name_definition+ is called.
    def table_constraint_definition
      contraint_name_definition
      table_constraint or return false
      constraint_characteristics
      return true
    end

    def unique_specification
      if get_token(UNIQUE) or get_token(PRIMARY_KEY) or get_token(:autoincriment) or
      ( get_token(:not) and get_token(:null)) or
      ( get_token(:default) and ( get_token(:number) or get_token(:literal)))
        return true
      else
        return nil
      end
    end

    def colunm_constraint
      unique_specification or check_constraint_definition or references_specification 
    end

    def column_constraint_definition
      colunm_constraint
    end

    # <column definition>
    # returns [Boolean]
    #
    # <column name> [ <data type> | <domain name> ] [ <reference scope check> ]
    #               [ <default clause> | <identity column specification> | <generation clause> ]
    #               [ <column constraint definition> ... ] [ <collate clause> ]
    def column_definition
      if cn = get_token(:ident) # column name
        if dt = get_token(:ident)
          if dt = get_token(:lparen)
            if dt = get_token(:ident)
              if dt = get_token(:comma)
                dt = get_token(:ident)
              end
            elsif dt = get_token(:number)
            end
            dt = get_token(:rparen)
          end
        end
	while column_constraint_definition

	end
        return true
      else
        return false
      end
    end
    # <table element list>    ::=   <left paren> <table element> [ { <comma> <table element> }... ] <right paren>
    def table_element_list
      if get_token(:lparen)
        table_element
        while get_token(:comma)
          table_element
        end
        get_token(:rparen)
      end
    end
    #  <table contents source>    ::= 
    #          <table element list>
    #      |     OF <path-resolved user-defined type name> [ <subtable clause> ] [ <table element list> ]
    #      |     <as subquery clause>
    def table_contents_source
      table_element_list
    end
    # <table commit action>    ::=   PRESERVE | DELETE
    def table_commit_action
    end
    # <table definition> ::=
    #     CREATE [ <table scope> ] TABLE <table name> <table contents source>
    #     [ ON COMMIT <table commit action> ROWS ]
    def table_definition
      raise unless @lexer.get_next_token.type == :create
      table_scope
      raise ParseError unless @lexer.get_next_token.type == :table
      table_name
      table_contents_source
      if get_token(:onP)
        raise unless @lexer.get_next_token == 'commit'
        table_commit_action
        raise unless @lexer.get_next_token == 'rows'
      end
      unless get_token(:end)
        raise "parser error #{@lexer.inspect}"
      end
    end
  end
end

__END__
