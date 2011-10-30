class DbMarshal

  module ClassMethods
    def adapter
      abcs[Rails.env]["adapter"]
    end

    def database
      abcs[Rails.env]["database"]
    end

    def abcs
      @abcs ||= ActiveRecord::Base.configurations
    end

    def dump_filename
      %{#{Rails.env}.#{Time.now.strftime('%Y-%m-%d@%H%M%S')}.sql}
    end

    def dump(filename=nil)
      filename ||= self.dump_filename
      cmd = %{#{self.adapter} "#{self.database}" ".dump" > "#{filename}"}
      system cmd
      return filename
    end

    def restore(filename)
      if File.exist?(self.database)
        ActiveRecord::Base.connection.select_values(%{SELECT name FROM sqlite_master WHERE type = 'table' AND NOT name = 'sqlite_sequence'}).each do |table|
          ActiveRecord::Base.connection.drop_table(table)
        end
      end
      cmd = %{#{self.adapter} "#{self.database}" < "#{filename}"}
      system cmd
      return true
    end
  end

  self.extend(ClassMethods)
end
