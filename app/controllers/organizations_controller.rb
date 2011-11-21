class OrganizationsController < ApplicationController
  def index
  	@organizations = Organization.all
  end

  def show
  end

  def new
  end

  def edit
  end

end
