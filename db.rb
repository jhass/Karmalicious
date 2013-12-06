require 'sqlite3'
require 'sequel'
require 'sequel/extensions/core_extensions'

DB = Sequel.connect('sqlite://karma.db')

class Karma < Sequel::Model
  attr_accessor :place
  def before_create
    self.created_at ||= Time.now
    super
  end
  
  def value
    self[:value].round(2)
  end
  
  def receiver
    @receiver ||= User.new self.to, self.value
  end
  
  def sender
    @sender ||= User.new self.from, self.value
  end
end

module UserMethods
  def karma
    (Karma.filter(to: self.nick).sum(:value) || 0).round(2)
  end

  def add_karma(val, from, channel)
    Karma.create(to: self.nick, from: from.nick, value: val, channel: channel)
  end

  def increase_karma_of(user, channel)
    user.karma_can_be_modified_by?(self) && user.add_karma(self.karma_influence, self, channel)
  end
  
  def decrease_karma_of(user, channel)
    user = user
    user.karma_can_be_modified_by?(self) && user.add_karma(-self.karma_influence, self, channel)
  end
  
  def karma_influence
    (1+self.karma*0.0125).round(2)
  end
  
  def karma_level
    return 0 if self.karma < 1
    (0.5+Math.log2(self.karma)).ceil
  end
  

  def karma_string
    "#{self.nick} has a karma of #{self.karma} (LVL: #{self.karma_level}, INF: #{self.karma_influence})"
  end
  
  def karma_can_be_modified_by?(user)
    !(self.nick == user.nick || Karma.first('`from` = ? AND `to` = ? AND created_at > ?', user.nick, self.nick, Time.now-5*60))
  end
end


class User
  include UserMethods
  attr_reader :nick
  def initialize(nick, karma=nil)
    @nick = nick
    @karma = karma
  end
  
  alias_method :query_karma, :karma
  def cached_karma
    @karma ||= query_karma
  end
  alias_method :karma, :cached_karma
  
  def total_karma_given
    (Karma.filter(from: self.nick).sum(:value) || 0).round(2)
  end
  
  def positive_karma
    Karma.filter('`from` = ? AND value > 0', self.nick)
  end
  
  def positive_karma_given
    (self.positive_karma.sum(:value) || 0).round(2)
  end
  
  def positive_karma_count
    self.positive_karma.count || 0
  end
  
  def negative_karma
    Karma.filter('`from` = ? AND value < 0', self.nick)
  end
  
  def negative_karma_given
    (self.negative_karma.sum(:value) || 0).round(2)
  end
  
  def negative_karma_count
    self.negative_karma.count || 0
  end
end
