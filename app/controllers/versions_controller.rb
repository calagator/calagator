class VersionsController < ApplicationController
  def edit
    @version = Version.find(params[:id])
    @record = @version.next.try(:reify) || @version.item || @version.reify

    singular = @record.class.name.singularize.underscore
    plural = @record.class.name.pluralize.underscore
    self.instance_variable_set("@#{singular}", @record)

    if request.xhr?
      render :partial => "/#{plural}/form", :locals => { singular.to_sym =>  @record }
    else
      render "#{plural}/edit", :locals => { singular.to_sym =>  @record }
    end
  end
end
