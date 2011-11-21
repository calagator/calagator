class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.all
  end

  # GET /organizations/1
  def show
    begin
      @organization = Organization.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      return redirect_to organizations_path, :flash => {:failure => e.to_s}
    end

    @page_title = @organization.name
  end

  # GET /organizations/new
  # GET /organizations/new.xml
  def new
    @organization = Organization.new(params[:organization])
    @page_title = "Add an Organization"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  def edit
  end

end
