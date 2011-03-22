class VersionsController < ApplicationController
  def index
    @versions = Defer { ::Version.paginate(:page => params[:page], :order => 'created_at desc', :per_page => 50) }
    respond_to do |format|
      format.html # changes.html.erb
      format.atom # changes.atom.builder
    end
  end

  def show
    begin
      @version = Version.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:failure] = "No such version."
      redirect_to(:action => :index)
    end
  end

  def update
    begin
      @version = Version.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:failure] = "No such version."
      return(redirect_to(:action => :index))
    end

    if @version.event == "create"
      @record = @version.item_type.constantize.find(@version.item_id)
      @result = @record.destroy
    else
      @record = @version.reify
      @result = @record.save
    end

    if @result
      if @version.event == "create"
        flash[:success] = "Rolled back to destroy record."
        redirect_to :action => :index
      else
        flash[:success] = "Rolled back record to earlier state."
        redirect_to url_for(:controller => @version.item_type.tableize, :action => "show", :id => @version.item_id)
      end
    else
      flash[:failure] = "Couldn't rollback. Sorry."
      redirect_to :action => :index
    end
  end
end
