# frozen_string_literal: true

#
# Copyright (c) 2019-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'expression_builder/constraint_maker'
require_relative 'expression_builder/order_maker'
require_relative 'expression_builder/select_maker'
require_relative 'expression_builder/where_maker'

module Dbee
  module Providers
    class ActiveRecordProvider
      # This class can generate an Arel expression tree.
      class ExpressionBuilder
        extend Forwardable

        def_delegators :statement, :to_sql

        def initialize(model, table_alias_maker, column_alias_maker)
          @model              = model
          @table_alias_maker  = table_alias_maker
          @column_alias_maker = column_alias_maker

          @base_table = Arel::Table.new(model.table)
          @base_table.table_alias = table_alias_maker.make(model.name)

          @statement = base_table
        end

        def add(query)
          query.fields.each   { |field| add_field(field) }
          query.sorters.each  { |sorter| add_sorter(sorter) }
          query.filters.each  { |filter| add_filter(filter) }

          add_limit(query.limit)

          self
        end

        private

        attr_reader :base_table,
                    :statement,
                    :model,
                    :table_alias_maker,
                    :column_alias_maker

        def tables
          @tables ||= {}
        end

        def key_paths_to_arel_columns
          @key_paths_to_arel_columns ||= {}
        end

        def where_maker
          @where_maker ||= WhereMaker.new
        end

        def order_maker
          @order_maker ||= OrderMaker.new
        end

        def select_maker
          @select_maker ||= SelectMaker.new
        end

        def constraint_maker
          @constraint_maker ||= ConstraintMaker.new
        end

        def add_filter(filter)
          add_key_path(filter.key_path)

          key_path    = filter.key_path
          arel_column = key_paths_to_arel_columns[key_path]

          predicate = where_maker.make(filter, arel_column)

          @statement = statement.where(predicate)

          self
        end

        def add_sorter(sorter)
          add_key_path(sorter.key_path)

          key_path = sorter.key_path
          arel_column = key_paths_to_arel_columns[key_path]

          predicate = order_maker.make(sorter, arel_column)

          @statement = statement.order(predicate)

          self
        end

        def add_field(field)
          add_key_path(field.key_path)

          key_path = field.key_path
          arel_column = key_paths_to_arel_columns[key_path]

          predicate = select_maker.make(field, arel_column, column_alias_maker)

          @statement = statement.project(predicate)

          self
        end

        def add_limit(limit)
          @limit = limit ? limit.to_i : nil

          @statement = @statement.take(limit) if limit

          self
        end

        def table(name, model, previous_table)
          table = Arel::Table.new(model.table)
          table.table_alias = table_alias_maker.make(name)

          on = constraint_maker.make(model.constraints, table, previous_table)

          @statement = statement.join(table, ::Arel::Nodes::OuterJoin)
          @statement = statement.on(on) if on

          tables[name] = table
        end

        def traverse_ancestors(ancestors)
          ancestors.each_pair.inject(base_table) do |memo, (name, model)|
            tables.key?(name) ? tables[name] : table(name, model, memo)
          end
        end

        def add_key_path(key_path)
          return if key_paths_to_arel_columns.key?(key_path)

          ancestors = model.ancestors(key_path.ancestor_names)

          table = traverse_ancestors(ancestors)

          arel_column = table[key_path.column_name]
          key_paths_to_arel_columns[key_path] = arel_column

          self
        end
      end
    end
  end
end
