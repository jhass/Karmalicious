Sequel.migration do
  up do
    create_table :karmas do
      primary_key :id
      String :from
      String :to
      Float :value
      Time :created_at
    end
  end
  
  down do
  end
end
