module VersionsHelper
  # Return HTML representing the +object+, which is either its text or a stylized "nil".
  def text_or_nil(object)
    if object.nil?
      return content_tag("em", "nil")
    else
      return h(object)
    end
  end

  # Return an hash of changes for the given +Version+ record. The resulting
  # data structure is a hash whose keys are the names of changed columns and
  # values containing a hash with current and previous value. E.g.,:
  #
  #   {
  #     "my_column_name" => {
  #       :previous => "past value",
  #       :current  => "current_value",
  #     },
  #     "title" => {
  #       :previous => "puppies",
  #       :current  => "kittens",
  #     },
  #     ...
  #   }
  def changes_for(version)
    changes = {}
    current = version.next.try(:reify)
    # FIXME #reify randomly throws "ArgumentError Exception: syntax error on line 13, col 30:" -- why?
    previous = version.reify rescue nil
    record = \
      begin
        version.item_type.constantize.find(version.item_id)
      rescue ActiveRecord::RecordNotFound
        previous || current
      end

    # Bail out if no changes are available
    return changes unless record

    case version.event
    when "create"
      current ||= record
    when "update"
      current ||= record
    when "destroy"
      previous ||= record
    else
      raise ArgumentError, "Unknown event: #{version.event}"
    end

    (current or previous).attribute_names.each do |name|
      next if name == "updated_at"
      next if name == "created_at"
      current_value = current.read_attribute(name) if current
      previous_value = previous.read_attribute(name) if previous
      unless current_value == previous_value
        changes[name] = {
          :previous => previous_value,
          :current => current_value,
        }
      end
    end

    return changes
  end

  # Returns string title for the versioned record.
  def title_for(version)
    current = version.next.try(:reify)
    # FIXME #reify randomly throws "ArgumentError Exception: syntax error on line 13, col 30:" -- why?
    previous = version.reify rescue nil
    record = version.item_type.constantize.find(version.item_id) rescue nil

    object = [previous, current, record].find { |o| o.present? }
    method = case object
             when Source then :url
             else :title
             end
    title =  truncate(object.send(method), :length => 100)
    return h(title)
  end
end
