class ChangesController < ApplicationController
  def show
    @versions = Defer { ::Version.paginate(:page => params[:page], :order => 'created_at desc', :per_page => 20) }
    respond_to do |format|
      format.html # changes.html.erb
      format.atom # changes.atom.builder
    end
  end
  
  def rollback_to
    version = Version.find(params[:version])
    @record = version.reify
    if @record.save
      redirect_to url_for(:controller => version.item_type.tableize, :action => "show", :id => version.item_id)
    else
      flash[:error] = "Couldn't rollback. Sorry."
      redirect_to :action => :show
    end
  end
end
