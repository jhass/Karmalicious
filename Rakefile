require 'bundler/setup'
require './db'
Sequel.extension :migration

namespace :db do
  task :migrate do
    Sequel::Migrator.apply DB, 'migrations/'
  end
end
