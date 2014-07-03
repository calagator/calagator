module SquashManyDuplicatesMixin
  def self.included(mixee)
    mixee.class_eval do

      # POST /venues/squash_multiple_duplicates
      def squash_many_duplicates
        # Derive model class from controller name
        model_class = self.controller_name.singularize.titleize.constantize

        master_id = params[:master_id].try(:to_i)
        duplicate_ids = params.keys.grep(/^duplicate_id_\d+$/){|t| params[t].to_i}
        singular = model_class.name.singularize.downcase
        plural = model_class.name.pluralize.downcase

        if master_id.nil?
          flash[:failure] = "A master #{singular} must be selected."
        elsif duplicate_ids.empty?
          flash[:failure] = "At least one duplicate #{singular} must be selected."
        elsif duplicate_ids.include?(master_id)
          flash[:failure] = "The master #{singular} could not be squashed into itself."
        else
          squashed = model_class.squash(:master => master_id, :duplicates => duplicate_ids)

          if squashed.size > 0
            message = "Squashed duplicate #{plural} #{squashed.map {|obj| obj.title}.inspect} into master #{master_id}."
            flash[:success] = flash[:success].nil? ? message : flash[:success] + message
          else
            message = "No duplicate #{plural} were squashed."
            flash[:failure] = flash[:failure].nil? ? message : flash[:failure] + message
          end
        end

        redirect_to :action => "duplicates", :type => params[:type]
      end

      def duplicates
        @type = params[:type]
        begin
          instance_variable = "@grouped_#{self.controller_name}".to_sym
          model_class_name = self.controller_name.classify
          model_class_object = model_class_name.constantize
          self.instance_variable_set(instance_variable, model_class_object.find_duplicates_by_type(@type))
        rescue ArgumentError => e
          self.instance_variable_set(instance_variable, {})
          flash[:failure] = "#{e}"
        end

        @page_title = "Duplicate #{model_class_name} Squasher"

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => self.instance_variable_get(instance_variable) }
        end
      end

    end
  end
end
