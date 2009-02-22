spec = Gem::Specification.new do |s| 
  s.name = "catch_cookie_exception"
  s.version = "1.0"
  s.author = "Michael Hartl"
  s.email = "michael@insoshi.com"
  s.homepage = "http://insoshi.com/"
  s.summary = "Catch and handle the CGI::Session::CookieStore::TamperedWithCookie exception that comes from changing the Rails secret string."
  s.files = ["README.markdown", "Rakefile", "catch_cookie_exception.gemspec",
             "lib/catch_cookie_exception.rb",
             "MIT-LICENSE"]
end
