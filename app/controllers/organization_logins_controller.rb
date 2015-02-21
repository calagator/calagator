class OrganizationLoginsController < ApplicationController
  def create
    if org = Organization.find_by_permalink(params[:permalink])
      session[:organization_id] = org.id
      redirect_to events_path
    else
      render :file => "#{Rails.root}/public/404.html",  :status => 404
    end
  end
end
