module VersionDiff
  def version_diff(n1, n2=:head)
    if n1 == :prev && n2.nil?
      n1 = :head
      n2 = :prev
    end
    
    n1 = self.version if n1 == :head
    n2 = self.version if n2 == :head
    
    if n2 == :prev
      n2 = n1
      n1 = n1-1 
    end
    
    raise(ArgumentError, "version cannot be 0") if n1 == 0 || n2 == 0
    v1 = self.versions.find(:first, :conditions => {:version => n1})
    v2 = self.versions.find(:first, :conditions => {:version => n2})
    
    v1.attributes = v2.attributes
    changed_fields = v1.changes
  end
end