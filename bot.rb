# encoding: utf-8
require 'bundler/setup'
require 'cinch'

require './db'
require './channel_list'

class Cinch::User
  include UserMethods
end

ADMINS = %w(jhass MrZYX DenSchub)
BLACKLIST = %w(c C)

def authorized? m
  ADMINS.include?(m.user.nick) && m.channel.nil?
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "Karmalicious"
    c.realname = "karmalicious.mrzyx.de"
    c.user = "karma"
    c.server = "irc.freenode.net"
    c.port = 6667
    c.channels = ChannelList.to_a
  end

  NICK_REGEX = /[\w\d\-_\^'´`]+/

  on :message, /^(#{NICK_REGEX})(\+\+|\-\-)/ do |m, nick, inc_or_dec|
    break unless m.channel
    method = (inc_or_dec == "++") ? :increase_karma_of : :decrease_karma_of
    break if BLACKLIST.include?(nick)
    user = User(nick)
    valid_user = user && user.nick != bot.nick && m.channel.has_user?(user)
    unless valid_user && m.user.public_send(method, user, m.channel.name)
      break if ChannelList[m.channel.name].silent?
      m.user.send "You can't modify the karma of #{nick} because #{nick} either isn't in the channel, a bot, that's your own name or you already did in the last five minutes."
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

  CHANNEL_REGEX = /#+[\w\d_\-]+/

  on :message, /^!join\s+(#{CHANNEL_REGEX})/ do |m, channel|
    break unless authorized?(m)
    synchronize(:joinpart) do
      unless bot.channels.include?(channel)
        ChannelList.join channel
        bot.join channel
      end
    end
  end

  on :message, /^!part\s+(#{CHANNEL_REGEX})/ do |m, channel|
    break unless authorized?(m)
    synchronize(:joinpart) do
      if bot.channels.include?(channel)
        ChannelList.part channel
        bot.part channel
      end
    end
  end

  on :message, /^!silent\s+(#{CHANNEL_REGEX})/ do |m, name|
    break unless authorized?(m)
    channel = ChannelList[name]
    if channel.nil?
      m.reply "I'm not in #{name}."
    elsif channel.silent?
      channel.verbose!
      m.reply "I'll be verbose in #{channel.name} from now on."
    else
      channel.silent!
      m.reply "I'll be silent in #{channel.name} from now on."
    end
  end

  on :message, /^#{config.nick}(?:\:|,|\s+)\s*(?:about|help|who a?re? (yo)?u|shut (the )?(fuck )?up|stfu|hello|hi|hey|o?hai|welcome|go( away)?|leave|part|join|come( to)?|site|website|page|webpage|info|man|gtfo).*/ do |m|
    break if m.channel && ChannelList[m.channel.name].silent?
    m.reply "Hi, I'm Karmalicious, I keep track of your karma. If you want to know more about me visit http://karmalicious.mrzyx.de"
  end
end

bot.loggers.level = :info
DB.sql_log_level = :info
DB.loggers << bot.loggers.first
bot.start
