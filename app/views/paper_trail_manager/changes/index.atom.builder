# frozen_string_literal: true

atom_feed do |feed|
  feed.title('Changes')
  date = @versions.first.try(:created_at) || Time.zone.at(0)
  feed.updated(date)

  @versions.each do |version|
    next unless change_show_allowed?(version)

    feed.entry(version, url: change_url(version)) do |entry|
      changes = changes_for(version)

      user = if PaperTrailManager.whodunnit_class && version.whodunnit
               begin
          PaperTrailManager.whodunnit_class.find(version.whodunnit)
               rescue StandardError
                 nil
        end
             end

      entry.title "#{version.event.upcase} #{version.item_type} «#{change_title_for(version)}» #{user ? 'by ' + user.send(PaperTrailManager.whodunnit_name_method) : ''}"
      entry.updated version.created_at.utc.xmlschema

      xm = ::Builder::XmlMarkup.new
      xm.div do
        xm.p do
          xm.span << 'Go to: '
          xm.span << link_to('Change', change_url(version))
          xm.span << ' | '
          xm.span << link_to('Record', change_item_url(version))
        end
        xm.table do
          changes.keys.sort.each do |key|
            xm.tr do
              xm.td { xm.b key }
              xm.td changes[key][:previous].inspect
              xm.td { xm.span << '&rarr;' }
              xm.td changes[key][:current].inspect
            end
          end
        end
      end

      entry.content(xm.to_s, type: 'html')
    end
  end
end
