class ChangesController < ApplicationController
  def show
    @versions = Defer { ::Version.paginate(:page => params[:page], :order => 'created_at desc', :per_page => 20) }
    respond_to do |format|
      format.html # changes.html.erb
      format.atom # changes.atom.builder
    end
  end

  def rollback_to
    begin
      @version = Version.find(params[:version])
    rescue ActiveRecord::RecordNotFound
      flash[:failure] = "No such version."
      return(redirect_to(:action => :show))
    end

    if @version.event == "create"
      @record = @version.item_type.constantize.find(@version.item_id)
      @result = @record.destroy
    else
      @record = @version.reify
      @result = @record.save
    end

    if @result
      redirect_to url_for(:controller => @version.item_type.tableize, :action => "show", :id => @version.item_id)
    else
      flash[:failure] = "Couldn't rollback. Sorry."
      return(redirect_to(:action => :show))
    end
  end
end
