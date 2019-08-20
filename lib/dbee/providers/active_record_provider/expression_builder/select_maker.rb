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
        # Derives Arel#project predicates.
        class SelectMaker
          def make(column, arel_column, alias_maker)
            column_alias = quote(alias_maker.make(column.display))

            arel_column.as(column_alias)
          end

          private

          def quote(value)
            ActiveRecord::Base.connection.quote(value)
          end
        end
      end
    end
  end
end
