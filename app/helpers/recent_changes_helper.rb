module RecentChangesHelper
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
  # values containing an array with the current and previous value. E.g.,:
  #
  #   {
  #     "my_column_name" => ["current_value", "past value"],
  #     ...
  #   }
  def changes_for(version)
    changes = {}

    a = version.item_type.constantize.find(version.item_id) rescue nil
    b = version.reify

    # TODO Why does this work?
    if a.nil? && b.nil?
      b = version.next.reify
    end

    (a or b).attribute_names.each do |name|
      next if name == "updated_at"
      next if name == "created_at"
      avalue = a.read_attribute(name) if a
      bvalue = b.read_attribute(name) if b
      unless avalue == bvalue
        changes[name] = [avalue, bvalue]
      end
    end

    return changes
  end
end
