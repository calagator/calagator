require 'facets/kernel/ergo'

RAILS_ROOT   = File.dirname(File.dirname(File.expand_path(__FILE__)))
RESTART_TXT  = "#{RAILS_ROOT}/tmp/restart.txt"

def get_current_revision
  return `(cd #{RAILS_ROOT} && git --no-pager log -1) 2>&1`
end

get '/' do
  @revision = get_current_revision

  haml :index
end

post '/' do
  @revision = get_current_revision

  action   = params[:action].ergo.to_s[/(\w+)/, 1]
  revision = params[:revision].ergo.to_s[/(\w+)/, 1]

  @command = nil
  common_bundle  = %{bundle check || bundle --local || sudo bundle}
  common_restart = %{(#{common_bundle}) && bundle exec rake RAILS_ENV=production clear && touch #{RESTART_TXT}}
  common_deploy  = %{(#{common_bundle}) && bundle exec rake RAILS_ENV=production db:migrate && #{common_restart}}
  case action
  when "deploy_and_migrate_via_update"
    if revision
      @command = %{git pull --rebase && git checkout #{revision} && #{common_deploy}}
    else
      @message = "ERROR: must specify revision to deploy via update"
    end
  when "restart", "start", "stop", "status"
    @command = %{#{common_restart}}
  end

  if @command
    @message = "Executing: #{@command}\n\n"
    @message << `(cd #{RAILS_ROOT} && #{@command}) 2>&1`
  end

  haml :index
end
