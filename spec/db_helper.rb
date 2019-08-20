# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# Enable logging using something like:
# ActiveRecord::Base.logger = Logger.new(STDERR)

def connect_to_db(name)
  config = yaml_file_read('spec', 'config', 'database.yaml')[name.to_s]
  ActiveRecord::Base.establish_connection(config)
end

def load_schema
  ActiveRecord::Schema.define do
    create_table :theaters do |t|
      t.column :name, :string
      t.column :partition, :string
      t.column :active, :boolean
      t.column :inspected, :boolean
      t.timestamps
    end

    create_table :members do |t|
      t.column :tid, :integer
      t.column :account_number, :string
      t.column :partition, :string
      t.timestamps
    end

    create_table :demographics do |t|
      t.column :member_id, :integer
      t.column :name, :string
      t.timestamps
    end

    create_table :phone_numbers do |t|
      t.column :demographic_id, :integer
      t.column :phone_type, :string
      t.column :phone_number, :string
      t.timestamps
    end

    create_table :movies do |t|
      t.column :member_id, :integer
      t.column :name, :string
      t.column :genre, :string
      t.column :favorite, :boolean, default: false, null: false
      t.timestamps
    end
  end
end
