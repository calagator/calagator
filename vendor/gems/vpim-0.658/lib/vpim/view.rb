=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require "enumerator"

module Vpim
  module View
    
    SECSPERDAY = 24 * 60 * 60

    # View only events occuring in the next week.
    module Week
      def each(klass = nil) #:nodoc:
        unless block_given?
          return Enumerable::Enumerator.new(self, :each, klass)
        end

        t0 = Time.new.to_a
        t0[0] = t0[1] = t0[2] = 0 # sec,min,hour = 0
        t0 = Time.local(*t0)
        t1 = t0 + 7 * SECSPERDAY

        # Need to filter occurrences, too. Create modules for this on the fly.
        occurrences = Module.new
        # I'm passing state into the module's instance methods by doing string
        # evaluation... which sucks, but I don't think I can get this closure in
        # there.
        occurrences.module_eval(<<"__", __FILE__, __LINE__+1)
          def occurrences(dountil=nil)
            unless block_given?
              return Enumerable::Enumerator.new(self, :occurrences, dountil)
            end
            super(dountil) do |t|
              t0 = Time.at(#{t0.to_i})
              t1 = Time.at(#{t1.to_i})
              break if t >= t1
              tend = t
              if respond_to? :duration
                tend += duration || 0
              end
              if tend >= t0
                yield t
              end
            end
          end
__
=begin
        block = lambda do |dountil| 
            unless block_given?
              return Enumerable::Enumerator.new(self, :occurrences, dountil)
            end
            super(dountil) do |t|
              break if t >= t1
              yield t
            end
        end
        occurrences.send(:define_method, :occurrences, block)
=end
        super do |ve|
          if ve.occurs_in?(t0, t1)
            if ve.respond_to? :occurrences
              ve.extend occurrences
            end
            yield ve
          end
        end
      end
    end

    # Return a calendar view for the next week.
    def self.week(cal)
      cal.clone.extend Week.dup
    end

    module Todo
    end

    # Return a calendar view of only todos (optionally, include todos that
    # are done).
    def self.todos(cal, withdone=false)
    end

  end
end

