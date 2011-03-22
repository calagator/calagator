cache "changes-show-atom" do
atom_feed do |feed|
  feed.title("#{SETTINGS.name} detailed changes")
  date = \
    @versions ?
      @versions.first.created_at :
      Time.at(0)
  feed.updated(date)

  @versions.each do |version|
    feed.entry(version, :url => version_url(version)) do |entry|
      changes = changes_for(version)
      user = Member.find(version.whodunnit) rescue nil

      entry.title "#{version.event.titleize} #{version.item_type} «#{title_for(version)}» #{user ? 'by '+user.name : ''}"
      entry.updated version.created_at.utc.xmlschema

      xm = ::Builder::XmlMarkup.new
      xm.div {
        xm.table {
          changes.keys.sort.each do |key|
            xm.tr {
              xm.td { xm.b key }
              xm.td changes[key][:previous].inspect
              xm.td { xm.span << "&rarr;" }
              xm.td changes[key][:current].inspect
            }
          end
        }
      }

      entry.content(xm.to_s, :type => 'html')
    end
  end
end
end
