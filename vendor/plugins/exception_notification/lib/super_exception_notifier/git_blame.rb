#Copyright (c) 2008-2009 Peter H. Boling of 9thBit LLC
#Released under the MIT license

module SuperExceptionNotifier
  module GitBlame

    def lay_blame(exception)
      error = {}
      unless(ExceptionNotifier.config[:git_repo_path].nil?)
        if(exception.class == ActionView::TemplateError)
            blame = blame_output(exception.line_number, "app/views/#{exception.file_name}")
            error[:author] = blame[/^author\s.+$/].gsub(/author\s/,'')
            error[:line]   = exception.line_number
            error[:file]   = exception.file_name
        else
          exception.backtrace.each do |line|
            file = exception_in_project?(line[/^.+?(?=:)/])
            unless(file.nil?)
              line_number = line[/:\d+:/].gsub(/[^\d]/,'')
              # Use relative path or weird stuff happens
              blame = blame_output(line_number, file.gsub(Regexp.new("#{RAILS_ROOT}/"),''))
              error[:author] = blame[/^author\s.+$/].sub(/author\s/,'')
              error[:line]   = line_number
              error[:file]   = file
              break
            end
          end
        end
      end
      error
    end

    def blame_output(line_number, path)
      app_directory = Dir.pwd
      Dir.chdir ExceptionNotifier.config[:git_repo_path]
      blame = `git blame -p -L #{line_number},#{line_number} #{path}`
      Dir.chdir app_directory

      blame
    end

    def exception_in_project?(path) # should be a path like /path/to/broken/thingy.rb
      dir = File.split(path).first rescue ''
      if(File.directory?(dir) and !(path =~ /vendor\/plugins/) and !(path =~ /vendor\/gems/) and path.include?(RAILS_ROOT))
        path
      else
        nil
      end
    end

  end
end
