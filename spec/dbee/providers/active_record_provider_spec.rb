# frozen_string_literal: true

#
# Copyright (c) 2019-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'
require 'db_helper'

describe Dbee::Providers::ActiveRecordProvider do
  let(:models) { yaml_fixture('models.yaml') }

  describe '#sql' do
    before(:all) do
      connect_to_db(:sqlite)
    end

    it 'errors when joining tables with no constraints' do
      model_hash = {
        name: :users,
        models: [
          { name: :logins }
        ]
      }

      query_hash = {
        fields: [
          { key_path: 'id' },
          { key_path: 'logins.id' }
        ]
      }

      query = Dbee::Query.make(query_hash)
      model = Dbee::Model.make(model_hash)

      error_class = Dbee::Providers::ActiveRecordProvider::ExpressionBuilder::MissingConstraintError

      expect { described_class.new.sql(model, query) }.to raise_error(error_class)
    end
  end

  describe 'Snapshot' do
    context 'Generating SQL' do
      %w[sqlite mysql].each do |dbms|
        context dbms do
          before(:all) do
            connect_to_db(dbms)
          end

          { readable: true, not_readable: false }.each_pair do |type, readable|
            context type.to_s do
              let(:key) { "#{dbms}_#{type}" }

              yaml_fixture_files('active_record_snapshots').each_pair do |filename, snapshot|
                specify File.basename(filename) do
                  model_name = snapshot['model_name']
                  query = Dbee::Query.make(snapshot['query'])
                  model = Dbee::Model.make(models[model_name])

                  expected_5_sql  = snapshot[key].to_s.chomp.tr("\n", ' ')
                  expected_6_sql  = expected_5_sql.gsub('  ', ' ').gsub("'t'", '1').gsub("'f'", '0')
                  actual_sql      = described_class.new(readable: readable).sql(model, query)

                  error_msg = <<~ERROR_MSG
                    Expected 5 SQL: #{expected_5_sql}
                    Expected 6 SQL: #{expected_6_sql}
                    Actual:         #{actual_sql}
                  ERROR_MSG

                  expect([expected_5_sql, expected_6_sql]).to include(actual_sql), error_msg
                end
              end
            end
          end
        end
      end
    end

    context 'Executing SQL' do
      %w[sqlite].each do |dbms|
        context dbms do
          before(:all) do
            connect_to_db(dbms)
            load_schema
          end

          { readable: true, not_readable: false }.each_pair do |type, readable|
            context type.to_s do
              let(:key) { "#{dbms}_#{type}" }

              yaml_fixture_files('active_record_snapshots').each_pair do |filename, snapshot|
                specify File.basename(filename) do
                  model_name = snapshot['model_name']
                  query = Dbee::Query.make(snapshot['query'])
                  model = Dbee::Model.make(models[model_name])

                  sql = described_class.new(readable: readable).sql(model, query)

                  expect { ActiveRecord::Base.connection.execute(sql) }.to_not raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
