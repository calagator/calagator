RAILS_ROOT = File.dirname(File.dirname(File.expand_path(__FILE__)))
RESTART_TXT = "#{RAILS_ROOT}/tmp/restart.txt"

get '/' do
  haml :index
end

post '/' do
  action = params[:action] ? params[:action].match(/(\w+)/)[1] : nil
  revision = params[:revision] ? params[:revision].match(/(\w+)/)[1] : nil

  @command = nil
  case action
  when "deploy"
    @command = %{svn cleanup && svn update -r #{revision} && touch #{RESTART_TXT}}
  when "restart", "start", "stop", "status"
    @command = %{touch #{RESTART_TXT}}
  end

  if @command
    @message = "Executing: #{@command}\n\n"
    @message << `(cd #{RAILS_ROOT} && #{@command}) 2>&1`
  end

  haml :index
end
