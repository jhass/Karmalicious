require 'yaml'

class ChannelList
  module ClassMethods
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

    def reload!
      list.reload!
      self
    end    

    def list
      @@list ||= self.new
    end
  end
  extend ClassMethods
  
  def initialize
    self.store! unless File.exists?('channels.yml')
    load!
  end
  
  def load!
    @channels = YAML.load_file "channels.yml"
  end
  alias_method :reload!, :load!

  def store!
    open('channels.yml', 'w') do |f|
      f.write YAML.dump @channels || []
    end
  end
  
  def add(chan)
    @channels.push(chan) unless @channels.include?(chan)
    self.store!
  end
  
  def rm(chan)
    @channels.delete(chan)
    self.store!
  end
  
  def to_a
    @channels
  end
end
