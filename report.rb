require 'csv'
require 'koala'

class Report
  def self.generate!(params)
    graph = Koala::Facebook::API.new(ENV['FB_ACCESS_TOKEN'])

    album_id = params[:album_id]
    stocking_date = params['stocking_date']
    stocking_time = params['stocking_time']
    buffer = params[:buffer]

    deadline = Time.new(*stocking_date.split('-'), *stocking_time.split(':'), 00, '+08:00')

    csv_string = CSV.generate do |csv|
      csv << ["Photo ID", "Name/Description", "Slots", "Names"]

      album = graph.get_connections album_id, 'photos'
      photo_ids = album.raw_response['data'].map { |x| x['id'] }

      names = []
      photo_ids.each do |photo_id|
        photo = graph.get_object photo_id

        slots_string = /SLOTS: (\d+)/.match(photo['name'])
        if slots_string
          slots = slots_string[1].to_i
          puts "my slots #{slots}"
          eligible_comments = photo['comments']['data'].select { |x| Time.parse(x['created_time']) >= deadline && x['message'].match(/mine/i) }.uniq { |x| x['from']['name'] }.slice(0, slots)
          names = eligible_comments.map { |x| [x['from']['name'], x['created_time']] }
        else
          eligible_comments = photo['comments']['data'].select { |x| Time.parse(x['created_time']) >= deadline && x['message'].match(/mine/i) }.uniq { |x| x['from']['name'] }
          names = eligible_comments.map { |x| [x['from']['name'], x['created_time']] }
        end

        names.each do |name_and_time|
          csv << if name_and_time == names.first
                   [photo_id, photo['name'], slots_string, name_and_time.first, name_and_time.last]
                 else
                   [nil, nil, nil, name_and_time.first, name_and_time.last]
                 end
        end

      end

    end
  end
end
