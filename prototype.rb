require 'koala'
require 'csv'

# get this from fb graph explorer
# https://developers.facebook.com/tools/explorer/
oauth_access_token = ''

@graph = Koala::Facebook::API.new(oauth_access_token)

album_id = ''

album = @graph.get_connections album_id, 'photos'

photo_ids = album.raw_response['data'].map { |x| x['id'] }

# easiest way is to get this from graph explorer as well
# deadline = Time.parse "2015-05-04T14:00:00+0000" # May 4, 2015 10:00PM
# deadline = Time.parse "2014-06-21T13:00:00+0000" # June 6, 2014 9:00PM

photo_ids.each do |photo_id|
  photo = @graph.get_object photo_id
  puts '=' * 100
  puts '*' * 100
  puts photo_id
  puts photo['name']
  puts '*' * 100
  slots_string = /SLOTS: (\d+)/.match(photo['name'])
  if slots_string
    slots = slots_string[1].to_i
    puts "my slots #{slots}"
    eligible_comments = photo['comments']['data'].select { |x| Time.parse(x['created_time']) >= deadline && x['message'].match(/mine/i) }.uniq { |x| x['from']['name'] }.slice(0, slots)
    eligible_comments.map { |x| puts "#{x['from']['name']}: #{x['created_time']}"}
  else
    eligible_comments = photo['comments']['data'].select { |x| Time.parse(x['created_time']) >= deadline && x['message'].match(/mine/i) }.uniq { |x| x['from']['name'] }
    eligible_comments.map { |x| puts "#{x['from']['name']}: #{x['created_time']}"}
  end
  puts '=' * 100
end
