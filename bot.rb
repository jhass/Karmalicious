# encoding: utf-8
require 'bundler/setup'
require 'cinch'

require './db'

class Cinch::User
  def karma
    Karma.filter(to: self.nick).sum(:value) || 0
  end

  def add_karma(val, from)
    Karma.create(to: self.nick, from: from.nick, value: val)
  end

  def increase_karma_of(user)
    user.karma_can_be_modified_by?(self) && user.add_karma(self.karma_influence, self)
  end
  
  def decrease_karma_of(user)
    user = user
    user.karma_can_be_modified_by?(self) && user.add_karma(-self.karma_influence, self)
  end
  
  def karma_influence
    1+self.karma*0.25
  end
  
  def karma_string
    "#{self.nick} has a karma of #{self.karma}"
  end
  
  def karma_can_be_modified_by?(user)
    !(self.nick == user.nick || Karma.first('`from` = ? AND created_at > ?', user.nick, Time.now-5*60))
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "MrZYXsKarmalicious"
    c.server = "chat.eu.freenode.net"
    c.port = 6667
    c.channels = ['##debot']
  end
  
  NICK_REGEX = /[\w\d\-_\^'´`]+/
  
  on :message, /^(#{NICK_REGEX})(\+\+|\-\-)/ do |m, nick, inc_or_dec|
    method = (inc_or_dec == "++") ? :increase_karma_of : :decrease_karma_of
    user = User(nick)
    valid_user = user && user.nick != bot.nick && m.channel.has_user?(user)
    unless valid_user && m.user.__send__(method, user)
      m.user.send "You can't modify the karma of #{nick} because he either isn't in the channel, a bot or you already did in the last five minutes"
    end
  end
  
  on :message, /^!karma$/ do |m|
    m.reply m.user.karma_string
  end
  
  on :message, /^!karma\s+(#{NICK_REGEX})$/ do |m, nick|
    user = User(nick)
    if user.nick == bot.nick
      m.reply "Bots have no karma :("
    else
      m.reply user.karma_string if user
    end
  end
end

#bot.loggers.level = :info
DB.sql_log_level = :debug
DB.loggers << bot.loggers.first
bot.start
