class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.all
  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    begin
      @organization = Organization.find(params[:id], :include => [:events])
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to(new_organization_path)
    end

    @page_title = @organization.name

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organization }
    end
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

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
  end


  # POST /organizations
  # POST /organizations.xml
  def create
    @organization = Organization.new(params[:organization])

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't create this organization because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && @organization.save
        flash[:success] = 'Organization was successfully created.'
        format.html { redirect_to( organization_path(@organization) ) }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.xml
  def update
    @organization = Organization.find(params[:id])

    respond_to do |format|
      if @organization.update_attributes(params[:organization])
        flash[:notice] = 'Organization was successfully updated.'
        format.html { redirect_to( organization_path(@organization) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end
end
