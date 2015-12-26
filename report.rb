require 'csv'
require 'koala'

class Report
  def self.generate!(params)
    graph = Koala::Facebook::API.new(ENV['FB_ACCESS_TOKEN'])

    album_id = params[:album_id]
    stocking_date = params['stocking_date']
    stocking_time = params['stocking_time']
    buffer = params[:buffer].to_i || 0

    deadline = Time.new(*stocking_date.split('-'), *stocking_time.split(':'), 00, '+08:00')

    csv_string = CSV.generate do |csv|
      csv << ["Photo ID", "Name/Description", "Slots", "Names"]

      album = graph.get_connections album_id, 'photos'
      photo_ids = album.raw_response['data'].map { |x| x['id'] }

      names = []
      eligible_comments = []
      photo_ids.each do |photo_id|
        photo = graph.get_object photo_id

        slots_string = /SLOTS: (\d+)/i.match(photo['name'])

        eligible_comments = graph.get_connections photo_id, 'comments', limit: 300
        eligible_comments.select! { |x| Time.parse(x['created_time']) >= deadline && x['message'].match(/mine/i) }.uniq { |x| x['from']['name'] }

        if slots_string
          slots = slots_string[1].to_i
          eligible_comments = eligible_comments.slice(0, slots + buffer)
        end

        names = eligible_comments.map { |x| [x['from']['name'], x['created_time']] }

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
