require 'rubygems'

Gem::Specification.new do |s|
  s.name          = "lucene_query"
  s.version       = "0.1"
  s.author        = "Jeremy Voorhis"
  s.email         = "jvoorhis@elevatedrails.com"
  s.homepage      = "http://www.elevatedrails.com/"
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Query builder for the Lucene (and Solr) search engine."
  s.files         = %w[ MIT-LICENSE
                        Rakefile
                        lib/lucene_query.rb
                        examples/lucene_query.rb ]
  s.has_rdoc      = false
end
