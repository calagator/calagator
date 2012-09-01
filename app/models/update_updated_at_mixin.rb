# WTF: Rails 3 no longer updates the #updated_at on #save, only on create or through #update_attributes. That's really stupid.
module UpdateUpdatedAtMixin
  def self.included(base)
    base.send:before_save, lambda { |record| record.updated_at = Time.zone.now }
  end
end
