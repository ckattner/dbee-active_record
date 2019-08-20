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
      # Derives new alias names and keeps count of ones already generated in order to avoid
      # collision.
      class ObfuscatedAliasMaker
        attr_reader :prefix

        def initialize(prefix = '')
          @counter  = -1
          @prefix   = prefix
        end

        def make(_name)
          increment
          current
        end

        private

        def current
          "#{prefix}#{@counter}"
        end

        def increment
          @counter += 1
        end
      end
    end
  end
end
