class WaitForSolr < Struct.new(:port)
  def self.on port, &block
    new(port).wait(&block)
  end

  def wait &block
    until solr_responds? do
      block.call
      sleep 1
    end
  end

  private

  def solr_responds?
    system %(curl -o /dev/null "http://localhost:#{port}/solr" > /dev/null 2>&1)
  end
end
