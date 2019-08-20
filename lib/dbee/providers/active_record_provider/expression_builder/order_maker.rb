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
        # Derives Arel#order predicates.
        class OrderMaker
          def make(sorter, arel_column)
            sorter.ascending? ? arel_column : arel_column.desc
          end
        end
      end
    end
  end
end
