require 'mail'
require 'tzinfo'


module VLCTechHub
  module Event
    class Mailer

      def self.publish event
        return false if ENV['EMAIL_FOR_PUBLICATION'].to_s.empty?

        zone = TZInfo::Timezone.get('Europe/Madrid')
        date = zone.utc_to_local(event['date'].utc)
        fmt_date = date.strftime "%d/%m/%Y %H:%M"

        Mail.deliver do
          to ENV['EMAIL_FOR_PUBLICATION']
          from 'VLCTechHub <vlctechhub@gmail.com>'
          subject "[VLCTECHHUB] Publicar: #{event['title']}"

          html_part do
            content_type 'text/html; charset=UTF-8'
            body "<h1>#{event['title']}</h1>" +
                "<pre>#{event['description']}</pre>" +
                "<h3>#{fmt_date}</h3>" +
                "<p>Hashtag: #{event['hashtag']}</p>" +
                "<p>Link: <a href='#{event['link']}'>#{event['link']}</a></p>" +
                "<p><a href='http://api.vlctechhub.org/v1/events/publish/#{event['publish_id']}'>Publicar evento</a></p>"
          end
        end
      end



      def self.broadcast event
        return false if ENV['EMAIL_FOR_BROADCAST'].to_s.empty?

        zone = TZInfo::Timezone.get('Europe/Madrid')
        date = zone.utc_to_local(event['date'].utc)
        fmt_date = date.strftime "%d/%m/%Y %H:%M"

        Mail.deliver do
          to ENV['EMAIL_FOR_BROADCAST']
          from 'VLCTechHub <vlctechhub@gmail.com>'
          subject "Nuevo evento: #{event['title']} #{fmt_date}"

          html_part do
            content_type 'text/html; charset=UTF-8'
            body "<h1>#{event['title']}</h1>" +
                 "<h3>#{fmt_date}</h3>" +
                 "<pre>#{event['description']}</pre>" +
                 "<p>Link: <a href='#{event['link']}'>#{event['link']}</a></p>"
         end
        end
      end
    end
  end
end
