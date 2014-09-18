require 'yaml'

class ChannelList
  Channel = Struct.new(:name, :silent) do
    alias_method :silent?, :silent

    def silent!
      self.silent = true
      ChannelList.list.store!
    end

    def verbose!
      self.silent = false
      ChannelList.list.store!
    end

    def ==(other)
      other.respond_to?(:name) && name == other.name
    end

    def hash
      name.hash
    end
  end

  FILENAME = 'channels.yml'.freeze

  class << self
    def to_a
      list.to_a
    end

    def add(chan)
      list.add(chan)
    end
    alias_method :join, :add
    alias_method :<<, :add

    def rm(chan)
      list.rm(chan)
    end
    alias_method :part, :rm
    alias_method :delete, :rm

    def [](name)
      list[name]
    end

    def reload!
      list.reload!
      self
    end

    def list
      @list ||= new
    end
  end

  include MonitorMixin

  def initialize
    super
    store! unless File.exists? FILENAME
    load!
  end

  def load!
    synchronize do
      @channels = YAML.load_file FILENAME
    end
    migrate! unless @channels.first.is_a? Channel
  end
  alias_method :reload!, :load!

  def store!
    synchronize do
      open('channels.yml', 'w') do |f|
        f.write YAML.dump @channels || []
      end
    end
  end

  def add(name)
    synchronize do
      channel = self[name]
      @channels.push(Channel.new(name, false)) unless channel
    end
    store!
  end

  def rm(name)
    synchronize do
      @channels.delete(self[name])
    end
    store!
  end

  def [](name)
    @channels.find {|channel| channel.name == name }
  end

  def migrate!
    synchronize do
      @channels = YAML.load_file(FILENAME).map {|name| Channel.new(name, false) }
    end
    store!
  end

  def to_a
    @channels.map(&:name)
  end
end
