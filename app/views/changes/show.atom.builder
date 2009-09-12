cache "changes-show-atom" do
atom_feed do |feed|
  feed.title("#{SETTINGS.name} detailed changes")
  feed.updated(@versions.ergo{|v| v.first.created_at } || Time.at(0))

  @versions.each_with_index do |version, i|
    feed.entry(version, :url => url_for(:controller => version.item_type.tableize, :action => "show", :id => version.item_id)) do |entry|
      changes = changes_for(version)
      user = Member.find(version.whodunnit) rescue nil

      entry.title "#{version.event.titleize} #{version.item_type}##{version.item_id} #{user ? 'by '+user.name : ''}"
      entry.updated version.created_at.utc.xmlschema

      xm = ::Builder::XmlMarkup.new
      xm.div {
        xm.table {
          changes.keys.sort.each do |key|
            xm.tr {
              xm.td { xm.b key }
              xm.td changes[key][0].inspect
              xm.td { xm.span << "&larr;" }
              xm.td changes[key][1].inspect
            }
          end
        }
      }

      entry.content(xm.to_s, :type => 'html')
    end
  end
end
end
