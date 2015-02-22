class OrganizationsController < ApplicationController
  # Provides #duplicates and #squash_many_duplicates
  include DuplicateChecking::ControllerActions

  # GET /organizations
  # GET /organizations.xml
  def index
    @search = Organization::Search.new(params)
    @organizations = @search.organizations

    respond_to do |format|
      format.html # index.html.erb
      format.kml  # index.kml.erb
      format.xml  { render :xml  => @organizations }
      format.json { render :json => @organizations, :callback => params[:callback] }
      format.js   { render :json => @organizations, :callback => params[:callback] }
    end
  end

  def autocomplete
    @organizations = Organization
      .non_duplicates
      .where(["LOWER(title) LIKE ?", "%#{params[:term]}%".downcase])
      .order('LOWER(title)')

    respond_to do |format|
      format.json { render :json => @organizations, :callback => params[:callback] }
    end
  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    @organization = Organization.find(params[:id], include: :source)

    return redirect_to @organization.duplicate_of if @organization.duplicate?

    respond_to do |format|
      format.html
      format.xml  { render xml: @organization }
      format.json { render json: @organization, callback: params[:callback] }
      format.ics  { render ics: @organization.events.order("start_time ASC").non_duplicates }
    end

  rescue ActiveRecord::RecordNotFound => e
    flash[:failure] = e.to_s
    redirect_to organizations_path
  end

  # GET /organizations/new
  # GET /organizations/new.xml
  def new
    if current_admin
      @organization = Organization.new
      render layout: params[:layout] != "false"
    else
      not_authorized
    end
  end

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
    unless current_admin || @organization == current_organization
      not_authorized
    end
  end

  # POST /organizations
  # POST /organizations.xml
  def create
    if current_admin
      @organization = Organization.new
      create_or_update
    else
      not_authorized
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.xml
  def update
    @organization = Organization.find(params[:id])
    if current_admin || @organization == current_organization
      create_or_update
    else
      not_authorized
    end
  end

  def create_or_update
    @organization.attributes = params[:organization]
    respond_to do |format|
      if !evil_robot? && @organization.save
        format.html { redirect_to from_event || @organization, flash: { success: "Organization was successfully saved." } }
        format.xml  { render xml: @organization, status: :created, location: @organization }
      else
        format.html { render action: @organization.new_record? ? "new" : "edit" }
        format.xml  { render xml: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.xml
  def destroy
    @organization = Organization.find(params[:id])

    if @organization.events.any?
      message = "Cannot destroy organization that has associated events, you must reassociate all its events first."
      respond_to do |format|
        format.html { redirect_to @organization, flash: { failure: message } }
        format.xml  { render xml: message, status: :unprocessable_entity }
      end
    else
      @organization.destroy
      respond_to do |format|
        format.html { redirect_to organizations_path, flash: { success: %("#{@organization.title}" has been deleted) } }
        format.xml  { head :ok }
      end
    end
  end

  def regenerate_permalink
    if current_admin
      redirect_to events_path, flash: { failure: 'Only admins can regenerate permalinks.' }
    end

    @organization = Organization.find(params[:organization_id])

    @organization.regenerate_permalink!
    redirect_to organization_path(@organization)
  end

  private

  def not_authorized
    redirect_to organizations_path, flash: { failure: "You are not permitted to modify this organization." }
  end

  def evil_robot?
    if params[:trap_field].present?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't save this organization because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end
  end

  def from_event
    Event.find_by_id(params[:from_event])
  end
end
