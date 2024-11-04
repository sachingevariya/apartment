# frozen_string_literal: true

# spec/apartment/adapters/postgresql_adapter_spec.rb

require 'spec_helper'
require 'shared_examples/schema_adapter_examples'

describe Apartment::Adapters::PostgresqlAdapter, database: :postgresql do
  subject(:adapter) { described_class.new(config) }

  it_behaves_like 'a schema based apartment adapter'

  context 'when using schemas with schema.rb' do
    before { Apartment.use_schemas = true }

    # Not sure why, but somehow using let(:tenant_names) memoizes for the whole example group, not just each test
    def tenant_names
      ActiveRecord::Base.connection.execute('SELECT nspname FROM pg_namespace;').pluck('nspname')
    end

    let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.schema_search_path.delete('"') } }

    it_behaves_like 'a schema based apartment adapter'
  end

  context 'when using schemas with SQL dump' do
    before do
      Apartment.use_schemas = true
      Apartment.use_sql = true
    end

    after do
      Apartment::Tenant.drop('has-dashes') if Apartment.connection.schema_exists?('has-dashes')
    end

    # Not sure why, but somehow using let(:tenant_names) memoizes for the whole example group, not just each test
    def tenant_names
      ActiveRecord::Base.connection.execute('SELECT nspname FROM pg_namespace;').collect { |row| row['nspname'] }
    end

    let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.schema_search_path.delete('"') } }

    it_behaves_like 'a schema based apartment adapter'

    it 'allows for dashes in the schema name' do
      expect { Apartment::Tenant.create('has-dashes') }.not_to(raise_error)
    end
  end

  context 'when using connections' do
    before { Apartment.use_schemas = false }

    # Not sure why, but somehow using let(:tenant_names) memoizes for the whole example group, not just each test
    def tenant_names
      connection.execute('select datname from pg_database;').collect { |row| row['datname'] }
    end

    let(:default_tenant) { subject.switch { ActiveRecord::Base.connection.current_database } }

    it_behaves_like 'a connection based apartment adapter'
  end
end