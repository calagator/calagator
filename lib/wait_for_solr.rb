require "timeout"

class WaitForSolr < Struct.new(:port)
  def self.on port, &block
    new(port).wait &block
  end

  def self.running_on? port
    new(port).responding?
  end

  def wait &block
    Timeout::timeout 10 do
      until responding? do
        block.call
        sleep 1
      end
    end
  end

  def responding?
    system %(curl -o /dev/null "http://localhost:#{port}/solr" > /dev/null 2>&1)
  end
end

