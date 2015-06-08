module Calagator

class VersionsController < Calagator::ApplicationController
  def edit
    @version = PaperTrail::Version.find(params[:id])
    @record = @version.next.try(:reify) || @version.item || @version.reify

    singular = @record.class.name.singularize.underscore.split("/").last
    plural = @record.class.name.pluralize.underscore.split("/").last
    self.instance_variable_set("@#{singular}", @record)

    if request.xhr?
      render :partial => "calagator/#{plural}/form", :locals => { singular.to_sym =>  @record }
    else
      render "calagator/#{plural}/edit", :locals => { singular.to_sym =>  @record }
    end
  end
end

end
