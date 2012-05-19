Sequel.migration do
  change do
    add_column :karmas, :channel, String
    self[:karmas].update(:channel => '#diaspora-de')
  end
end
