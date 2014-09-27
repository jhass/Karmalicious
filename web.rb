require 'bundler/setup'
require 'sinatra'
require 'sinatra/partial'

require './db'
require './channel_list'

class App < Sinatra::Application
  set :environment, :production
  set :haml, :format => :html5
  enable :partial_underscores

  get '/' do
    place = 1
    @top50 = Karma.select('SUM(value) AS value, `to`'.lit).group(:to)
      .order(:value.desc).limit(50).all.map do |u|
        u.place = place
        place += 1
        u
    end
    haml :index
  end


  get /\/u\/(.+)/ do |user|
    @user = User.new user
    @received_karma = Karma.filter(to: user).order(:created_at.desc).all
    redirect '/' if @received_karma.empty?
    @received_karma.map! {|k| [k.sender, k.value, k.channel, k.created_at]}
    @send_karma = Karma.filter(from: user).order(:created_at.desc).all
    @send_karma.map! {|k| [k.receiver, k.value, k.channel, k.created_at]}
    haml :show
  end
end
