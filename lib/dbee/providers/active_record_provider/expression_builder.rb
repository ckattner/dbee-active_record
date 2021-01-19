# frozen_string_literal: true

#
# Copyright (c) 2019-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'maker'

module Dbee
  module Providers
    class ActiveRecordProvider
      # This class can generate an Arel expression tree.
      # rubocop:disable Metrics/ClassLength
      # TODO: fix ClassLength when I refactor to_sql to take the query.
      class ExpressionBuilder < Maker # :nodoc: all
        class MissingConstraintError < StandardError; end

        def initialize(schema, table_alias_maker, column_alias_maker)
          super(column_alias_maker)

          @schema            = schema
          @table_alias_maker = table_alias_maker

          clear
        end

        # TODO: make clear and add private, and have to_sql take the query
        def clear
          @requires_group_by  = false
          @group_by_columns   = []
          @select_all         = true
          @from_model =       nil

          self
        end

        # rubocop:disable Metrics/AbcSize
        # TODO: fix AbcSize when I refactor to_sql to take the query.
        def add(query)
          return self unless query

          @from_model = schema.model_for_name!(query.from)
          @base_table = make_table(from_model.table, @from_model.name)
          build(base_table)

          query.fields.each   { |field| add_field(field) }
          query.sorters.each  { |sorter| add_sorter(sorter) }
          query.filters.each  { |filter| add_filter(filter) }

          add_partitioners(base_table, from_model.partitioners)
          add_limit(query.limit)

          self
        end
        # rubocop:enable Metrics/AbcSize

        def to_sql
          if requires_group_by
            @requires_group_by = false
            statement.group(group_by_columns) unless group_by_columns.empty?
            @group_by_columns = []
          end

          return statement.project(select_maker.star(base_table)).to_sql if select_all

          statement.to_sql
        end

        private

        attr_reader :base_table,
                    :from_model,
                    :statement,
                    :table_alias_maker,
                    :requires_group_by,
                    :group_by_columns,
                    :schema,
                    :select_all

        def tables
          @tables ||= {}
        end

        def key_paths_to_arel_columns
          @key_paths_to_arel_columns ||= {}
        end

        def add_filter(filter)
          add_key_path(filter.key_path)

          key_path    = filter.key_path
          arel_column = key_paths_to_arel_columns[key_path]
          predicate   = where_maker.make(filter, arel_column)

          build(statement.where(predicate))

          self
        end

        def add_sorter(sorter)
          add_key_path(sorter.key_path)

          key_path    = sorter.key_path
          arel_column = key_paths_to_arel_columns[key_path]
          predicate   = order_maker.make(sorter, arel_column)

          build(statement.order(predicate))

          self
        end

        def add_filter_key_paths(filters)
          filters.each_with_object({}) do |filter, memo|
            arel_key_column = add_key_path(filter.key_path)

            memo[arel_key_column] = filter
          end
        end

        def add_field(field)
          @select_all                 = false
          arel_value_column           = add_key_path(field.key_path)
          arel_key_columns_to_filters = add_filter_key_paths(field.filters)

          predicate = select_maker.make(
            field,
            arel_key_columns_to_filters,
            arel_value_column
          )

          build(statement.project(predicate))

          if field.aggregator?
            @requires_group_by = true
          else
            group_by_columns << arel_value_column
          end

          self
        end

        def add_limit(limit)
          limit = limit ? limit.to_i : nil

          build(statement.take(limit))

          self
        end

        def add_partitioners(table, partitioners)
          partitioners.each do |partitioner|
            arel_column = table[partitioner.name]
            predicate   = arel_column.eq(partitioner.value)

            build(statement.where(predicate))
          end

          self
        end

        def table(ancestor_names, relationship, model, previous_table)
          table = make_table(model.table, ancestor_names)

          on = constraint_maker.make(relationship.constraints, table, previous_table)

          raise MissingConstraintError, "for: #{ancestor_names}" unless on

          build(statement.join(table, ::Arel::Nodes::OuterJoin))
          build(statement.on(on))

          add_partitioners(table, model.partitioners)

          tables[ancestor_names] = table
        end

        # Takes a query path which is a list of relationship then models
        # repeating and converts it into an array of tuples of corresponding
        # relationship and models.
        def relationship_model_tuples(query_path)
          query_path.chunk_while { |_first, second| second.is_a?(Dbee::Model) }
        end

        def traverse_query_path(query_path)
          visited_path = []
          rel_models = relationship_model_tuples(query_path)

          rel_models.inject(base_table) do |prev_model, (relationship, next_model)|
            visited_path += [relationship.name]
            if tables.key?(visited_path)
              tables[visited_path]
            else
              table(visited_path, relationship, next_model, prev_model)
            end
          end
        end

        def add_key_path(key_path)
          return key_paths_to_arel_columns[key_path] if key_paths_to_arel_columns.key?(key_path)

          query_path = schema.expand_query_path(from_model, key_path)
          table = traverse_query_path(query_path)

          arel_column = table[key_path.column_name]

          # Note that this returns arel_column
          key_paths_to_arel_columns[key_path] = arel_column
        end

        def build(new_expression)
          @statement = new_expression
        end

        def make_table(table_name, alias_name)
          Arel::Table.new(table_name).tap do |table|
            table.table_alias = table_alias_maker.make(alias_name)
          end
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
