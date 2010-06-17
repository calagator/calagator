require 'open-uri'

# = Downloader
#
# This is a class for downloading with whatever the best tool available is, which can be curl, wget
class Downloader
  class Tool < Struct.new(:name, :checker, :fetcher)
    def present?
      return(`#{self.checker} 2>&1` && $?.to_i == 0)
    end

    def fetch(source, target)
      system "#{self.fetcher.call(source, target)} 2>&1"
    end
  end

  TOOLS = [
    Tool.new(:curl, 'curl --version', lambda{|source, target| "curl -o #{target} #{source}"}),
    Tool.new(:wget, 'wget --version',  lambda{|source, target| "wget --progress=bar:force -O #{target} -N #{source}"}),
  ]

  def self.download(source, target)
    for tool in TOOLS
      if tool.present?
        return tool.fetch(source, target)
      end
    end

    File.open(target, 'wb+') do |writer|
      # NOTE Do not use File.open, because "open-uri" doesn't intercept URL calls to that.
      open(source, 'rb') do |reader|
        writer.write(reader.read)
      end
    end
  end
end
