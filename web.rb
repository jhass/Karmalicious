require 'bundler/setup'
require 'sinatra'
require 'sinatra/partial'

require './db'

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
  puts @top50
  haml :index
end
