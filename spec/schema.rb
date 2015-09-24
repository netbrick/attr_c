ActiveRecord::Schema.define do
  self.verbose = false

  create_table :devices, force: true do |t|
    t.float :lat
    t.float :lon
    t.datetime :last_activity
    t.string :key
    t.string :name

    t.timestamps null: false
  end

  create_table :users, force: true do |t|
    t.float :lat
    t.datetime :last_activity
    t.string :name
    t.string :key

    t.timestamps null: false
  end
end
