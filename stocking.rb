require 'sinatra'
require 'pry'
require './report'

get '/' do
  haml :index
end

post '/report' do
  content_type 'application/csv'
  attachment "report.csv"
  Report.generate! params
end
