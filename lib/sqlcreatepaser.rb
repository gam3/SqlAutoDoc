require 'set';
require 'pp';

class SqlCreateTableParser
  class Token
    attr_accessor :value
    attr_accessor :type
  end
  class Lexer
    @@ident = Regexp.new('\A(?:' + ['(?:[_[[:alpha:]]][_$[[:alnum:]]]*)', '(?:"(?:[^"]|"")*")' ].join('|') + ')')

    def initialize(str)
      @input = str
    end
    def get_next_token
      if @return_previous_token
        @return_previous_token = false
        return @previous_token
      end

      token = Token.new

      raise ArgumentError.new("lexer error") if @input.nil?
      @input.lstrip!
      case @input
      when ''
	token.type = :end
      when /\A\(/
	token.type = :lparen
      when /\A,/
	token.type = :comma
      when /\A\)/
	token.type = :rparen
      when /\A\./
        token.type = :dot
      when /\ACOMMIT\b/i
        token.type = :commit
      when /\AON\b/i
        token.type = :on
      when /\AUNIQUE\b/i
        token.type = :unique
      when /\APRIMARY KEY\b/i
        token.type = :primary_key
      when /\ACREATE\b/i
        token.type = :create
      when /\ATABLE\b/i
        token.type = :table
      when /\A[0-9]+\d/
        token.type = :number
        token.value = $~
      when @@ident
        token.type = :ident
        token.value = $~
      when /\A\([^)]*\)/
        token.type = :ident
        token.value = $~
      else
	raise "unknown token #{@input}"
      end
      @input = $'
      @input.lstrip! if @input

      @previous_token = token
      token
    end
    def revert
      raise 'only call revert once' if @return_previous_token
      @return_previous_token = true
    end
  end
  class ParseError < StandardError
  end
  def initialize
    @lexer = Lexer.new("create table allen (id integer, name text(10))")
  end
  def table_scope
  end
  def table_name
    t1 = @lexer.get_next_token
    raise unless t1.type == :ident
  end
  def get_token(type)
    t1 = @lexer.get_next_token

    if t1.type == type
      return t1
    else
      @lexer.revert
      return nil
    end
  end
  def table_element
    if cn = get_token(:ident)
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
    end
  end
  def table_element_list
    if get_token(:lparen)
      table_element
      while get_token(:comma)
        table_element
      end
      get_token(:rparen)
    end
  end
  def table_contents_source
    table_element_list
  end
  def table_commit_action
  end
  def table_definition
    raise unless @lexer.get_next_token.type == :create
    table_scope
    raise ParseError unless @lexer.get_next_token.type == :table
    table_name
    table_contents_source
    token = @lexer.get_next_token
    unless token.type == :end
      raise unless @lexer.get_next_token == :on
      raise unless @lexer.get_next_token == 'commit'
      table_commit_action
      raise unless @lexer.get_next_token == 'rows'
    end
  end
end

puts SqlCreateTableParser.new.table_definition

__END__

<table definition>    ::= 
         CREATE [ <table scope> ] TABLE <table name> <table contents source>
         [ ON COMMIT <table commit action> ROWS ]

<table contents source>    ::= 
         <table element list>
     |     OF <path-resolved user-defined type name> [ <subtable clause> ] [ <table element list> ]
     |     <as subquery clause>

<table scope>    ::=   <global or local> TEMPORARY

<global or local>    ::=   GLOBAL | LOCAL

<table commit action>    ::=   PRESERVE | DELETE

<table element list>    ::=   <left paren> <table element> [ { <comma> <table element> }... ] <right paren>

<table element>    ::= 
         <column definition>
     |     <table constraint definition>
     |     <like clause>
     |     <self-referencing column specification>
     |     <column options>
