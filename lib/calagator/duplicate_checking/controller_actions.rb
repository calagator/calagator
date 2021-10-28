# frozen_string_literal: true

module Calagator
  module DuplicateChecking
    module ControllerActions
      # GET /#{model_class}/duplicates
      def duplicates
        @type = params[:type] || 'na'
        @grouped = model_class.find_duplicates_by_type(@type)
      rescue ArgumentError => e
        @grouped = {}
        flash[:failure] = e.to_s
      end

      # POST /#{model_class}/squash_multiple_duplicates
      def squash_many_duplicates
        primary = model_class.find_by(id: params[:primary_id])
        duplicate_ids = params.keys.grep(/^duplicate_id_\d+$/) { |t| params[t].to_i }
        duplicates = model_class.where(id: duplicate_ids)

        squasher = model_class.squash(primary, duplicates)
        if squasher.success
          flash[:success] = squasher.success
        else
          flash[:failure] = squasher.failure
        end
        redirect_to action: 'duplicates', type: params[:type]
      end

      private

      def model_class
        # Derive model class from controller name
        "Calagator::#{controller_name.singularize.titleize}".constantize
      end
    end
  end
end
