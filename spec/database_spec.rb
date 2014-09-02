# encoding: utf-8

require 'test_helper'

require 'minitest/spec'
require 'minitest/autorun'

require 'sqlautodoc'

module SqlAutoDoc
  describe Database do
    describe :reset do
      it 'must remove all Database' do
        Database.add_database('bob').must_be_instance_of Database
        Database.add_database('bill').must_be_instance_of Database
        Database.size.must_equal 2
        Database.reset
        Database.size.must_equal 0
      end
    end
    describe :add_database do
      before do
        Database.reset
      end
      it 'must return Database' do
        Database.add_database('bob').must_be_instance_of Database
      end
    end
    describe :get_database do
      before do
        Database.reset
      end
      it 'must raise ArgumentError' do
        lambda { Database.get_database('bob') }.must_raise ArgumentError
      end
      it 'must return Database' do
        Database.add_database('bob')
        Database.get_database('bob').must_be_instance_of Database
      end
    end
  end
  class Database
    describe '#add_schema' do
      before do
	Database.reset
        @db = Database.add_database('bob')
      end
      it 'must return Database' do
        @db.add_schema('public').must_be_instance_of Database::Schema
      end
    end
    describe '#get_schema' do
      before do
	Database.reset
        @db = Database.add_database('bob')
      end
      it 'must raise ArgumentError' do
        lambda { @db.get_schema('public') }.must_raise ArgumentError
      end
      it 'must return Database' do
        @db.add_schema('bob')
        @db.get_schema('bob').must_be_instance_of Database::Schema
      end
    end
  end
end

