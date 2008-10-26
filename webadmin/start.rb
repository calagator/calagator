require 'facets/kernel/ergo'

SVN_REPO     = "https://calagator.googlecode.com/svn/"
SVN_CHECKOUT = ".."
RAILS_ROOT   = File.dirname(File.dirname(File.expand_path(__FILE__)))
RESTART_TXT  = "#{RAILS_ROOT}/tmp/restart.txt"

def get_current_branch
  return `svn info #{SVN_CHECKOUT}`[/URL: ([^\n]+)/, 1].sub(SVN_REPO, '')
end

def get_current_revision
  return `svn info #{SVN_CHECKOUT}`[/Revision: (\d+)/, 1]
end

get '/' do
  @branch   = get_current_branch
  @revision = get_current_revision

  haml :index
end

post '/' do
  @branch   = get_current_branch
  @revision = get_current_revision

  action   = params[:action].ergo.to_s[/(\w+)/, 1]
  revision = params[:revision].ergo.to_s[/(\w+)/, 1]
  branch   = params[:branch].ergo.to_s[/([\/\w]+)/, 1]

  @command = nil
  common_restart = %{rake RAILS_ENV=production server:clear tmp:cache:clear && touch #{RESTART_TXT}}
  common_deploy  = %{rake RAILS_ENV=production db:migrate && #{common_restart}}
  case action
  when "deploy_and_migrate_via_update"
    if revision
      @command = %{svn cleanup && svn update -r #{revision} && #{common_deploy}}
    else
      @message = "ERROR: must specify revision to deploy via update"
    end
  when "deploy_and_switch_via_switch"
    if branch
      # #{revision.ergo{'-r '+self.to_s}}
      @command = %{svn cleanup && svn switch #{SVN_REPO}/#{branch} && #{common_deploy}}
    else
      @message = "ERROR: must specify branch to deploy via switch"
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
