require 'sqlite3'
require 'sequel'

DB = Sequel.connect('sqlite://karma.db')

class Karma < Sequel::Model
  def before_create
    self.created_at ||= Time.now
    super
  end
end
