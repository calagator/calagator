require 'timeout'

class WaitForSolr < Struct.new(:port, :timeout)
  def self.on(port, timeout, &block)
    new(port, timeout).wait &block
  end

  def self.running_on?(port)
    new(port).responding?
  end

  def wait
    Timeout.timeout timeout do
      until responding?
        yield
        sleep 1
      end
    end
  end

  def responding?
    system %(curl -o /dev/null "http://localhost:#{port}/solr" > /dev/null 2>&1)
  end
end
