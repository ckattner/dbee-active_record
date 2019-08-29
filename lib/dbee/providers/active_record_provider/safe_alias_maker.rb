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
      # This class can be used when readable alias names are expected.
      class SafeAliasMaker
        def make(*parts)
          parts.flatten
               .join('_')
               .tr('.', '_')
        end
      end
    end
  end
end
