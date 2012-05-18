require 'sequel'
DB = Sequel.connect('sqlite://karma.db')
DB.create_table :karmas do
  primary_key :id
  String :from
  String :to
  Float :value
  Time :created_at
end
