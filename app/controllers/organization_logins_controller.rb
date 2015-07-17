class OrganizationLoginsController < ApplicationController
  def create
    if org = Organization.find_by_permalink(params[:permalink])
      session[:organization_id] = org.id
      redirect_to root_path, flash: { success: 'Logged in.' }
    else
      render :file => "#{Rails.root}/public/404.html",  :status => 404
    end
  end

  def destroy
    session[:organization_id] = nil
    redirect_to events_path, flash: { success: 'Logged out.' }
  end
end
