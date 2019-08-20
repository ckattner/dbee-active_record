# frozen_string_literal: true

#
# Copyright (c) 2019-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module Dbee
  module Providers
    class ActiveRecordProvider
      class ExpressionBuilder
        # Derives Arel#where predicates.
        class WhereMaker
          METHODS = {
            Query::Filters::Contains => ->(column, val) { column.matches("%#{val}%") },
            Query::Filters::Equals => ->(column, val) { column.eq(val) },
            Query::Filters::GreaterThan => ->(column, val) { column.gt(val) },
            Query::Filters::GreaterThanOrEqualTo => ->(column, val) { column.gteq(val) },
            Query::Filters::LessThan => ->(column, val) { column.lt(val) },
            Query::Filters::LessThanOrEqualTo => ->(column, val) { column.lteq(val) },
            Query::Filters::NotContain => ->(column, val) { column.does_not_match("%#{val}%") },
            Query::Filters::NotEquals => ->(column, val) { column.not_eq(val) },
            Query::Filters::NotStartWith => ->(column, val) { column.does_not_match("#{val}%") },
            Query::Filters::StartsWith => ->(column, val) { column.matches("#{val}%") }
          }.freeze

          private_constant :METHODS

          def make(filter, arel_column, model_column)
            coerced_values = Array(filter.value).map { |v| model_column.coerce(v) }

            predicates = coerced_values.map do |coerced_value|
              method = METHODS[filter.class]

              raise ArgumentError, "cannot compile filter: #{filter}" unless method

              method.call(arel_column, coerced_value)
            end

            clause = predicates.shift

            predicates.each do |predicate|
              clause = clause.or(predicate)
            end

            clause
          end
        end
      end
    end
  end
end
