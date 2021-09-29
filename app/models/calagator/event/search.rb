# frozen_string_literal: true

module Calagator
  class Event < ApplicationRecord
    class Search < Struct.new(:query, :tag, :order, :current)
      def initialize(attributes = {})
        members.each do |key|
          send "#{key}=", attributes[key]
        end
        self.order ||= 'date'
        validate!
      end

      def events
        @events ||= perform_search
      end

      # Return +events+ grouped by currentness using a data structure like:
      #
      #   {
      #     :current => [ my_current_event, my_other_current_event ],
      #     :past => [ my_past_event ],
      #   }
      def grouped_events
        grouped = events.group_by(&:current?)
        grouped = { current: grouped[true] || [], past: grouped[false] || [] }
        grouped[:current].reverse! if order.to_s == 'date'
        grouped[:past] = [] if current
        grouped
      end

      def current
        %w[1 true].include?(super)
      end

      attr_reader :failure_message

      def hard_failure?
        @hard_failure
      end

      private

      def perform_search
        if hard_failure?
          []
        elsif tag
          Event.search_tag(tag, order: order, current: current)
        else
          Event.search(query, order: order, skip_old: current)
        end
      rescue ActiveRecord::StatementInvalid => e
        @failure_message = 'There was an error completing your search.'
        @hard_failure = true
        []
      end

      def validate!
        unless %w[date name title venue score].include?(order) || order.blank?
          @failure_message = "Unknown ordering option #{order.inspect}, sorting by date instead."
        end

        if tag.present? && order == 'score'
          @failure_message = 'You cannot sort tags by score'
        end

        if [query, tag].all?(&:blank?)
          @failure_message = 'You must enter a search query'
          @hard_failure = true
        end

        if [query, tag].all?(&:present?)
          # TODO: make it possible to search by tag and query simultaneously
          @failure_message = "You can't search by tag and query at the same time"
          @hard_failure = true
        end
      end
    end
  end
end
