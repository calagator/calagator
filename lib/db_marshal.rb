class DbMarshal

  module ClassMethods
    def adapter
      abcs[RAILS_ENV]["adapter"]
    end

    def database
      abcs[RAILS_ENV]["database"]
    end

    def abcs
      @abcs ||= ActiveRecord::Base.configurations
    end

    def dump_filename
      %{#{RAILS_ENV}.#{Time.now.strftime('%Y-%m-%d@%H%M%S')}.sql}
    end

    def dump(filename=nil)
      filename ||= self.dump_filename
      cmd = %{#{self.adapter} "#{self.database}" ".dump" > "#{filename}"}
      system cmd
      return filename
    end

    def restore(filename)
      File.unlink(self.database) if File.exist?(self.database)
      cmd = %{#{self.adapter} "#{self.database}" < "#{filename}"}
      system cmd
      return true
    end
  end

  self.extend(ClassMethods)
end
