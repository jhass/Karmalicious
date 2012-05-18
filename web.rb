require 'bundler/setup'
require 'sinatra'
require 'sinatra/partial'

require './db'

set :haml, :format => :html5
enable :partial_underscores

get '/' do
  @top50 = Karma.select('SUM(value) AS value, `to`'.lit).group(:to).order(:value.desc).limit(50).all
  @place = 0
  haml :index
end
