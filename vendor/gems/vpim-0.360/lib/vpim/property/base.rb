=begin
  Copyright (C) 2006 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

module Vpim
  class Icalendar
    module Set #:nodoc:
      module Util #:nodoc:

        def rm_all(name)
          rm = @comp.properties.select { |f| f.name? name }
          rm.each { |f| @comp.properties.delete(f) }
        end

        def set_token(name, allowed, default, value) #:nodoc:
          value = value.to_str
          unless allowed.include?(value)
            raise Vpim::Unencodeable, "Invalid #{name} value '#{value}'"
          end
          rm_all(name)
          unless value == default
            @comp.properties.push Vpim::DirectoryInfo::Field.create(name, value)
          end
        end

        def field_create(name, value, default_value_type = nil, value_type = nil, params = {})
          if value_type && value_type != default_value_type
            params['VALUE'] = value_type
          end
          Vpim::DirectoryInfo::Field.create(name, value, params)
        end

        def set_date_or_datetime(name, default, value)
          f = nil
          case value
          when Date
            f = field_create(name, Vpim.encode_date(value), default, 'DATE')
          when Time
            f = field_create(name, Vpim.encode_date_time(value), default, 'DATE-TIME')
          else
            raise Vpim::Unencodeable, "Invalid #{name} value #{value.inspect}"
          end
          rm_all(name)
          @comp.properties.push(f)
        end

        def set_datetime(name, value)
          f = field_create(name, Vpim.encode_date_time(value))
          rm_all(name)
          @comp.properties.push(f)
        end

        def set_text(name, value)
          f = field_create(name, Vpim.encode_text(value))
          rm_all(name)
          @comp.properties.push(f)
        end

        def set_text_list(name, value)
          f = field_create(name, Vpim.encode_text_list(value))
          rm_all(name)
          @comp.properties.push(f)
        end

        def set_integer(name, value)
          value = value.to_int.to_s
          f = field_create(name, value)
          rm_all(name)
          @comp.properties.push(f)
        end

        def add_address(name, value)
          f = value.encode(name)
          @comp.properties.push(f)
        end

        def set_address(name, value)
          rm_all(name)
          add_address(name, value)
        end

      end
    end

    module Property #:nodoc:

      # FIXME - rename Base to Util
      module Base #:nodoc:
        # Value of first property with name +name+
        def propvalue(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = prop.value
          end
          prop
        end

        # Array of values of all properties with name +name+
        def propvaluearray(name) #:nodoc:
          @properties.select{ |f| f.name? name }.map{ |p| p.value }
        end


        def propinteger(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = Vpim.decode_integer(prop.value)
          end
          prop
        end

        def proptoken(name, allowed, default_token = nil) #:nodoc:
          prop = propvalue name

          if prop
            prop = prop.to_str.upcase
            unless allowed.include?(prop)
              raise Vpim::InvalidEncodingError, "Invalid #{name} value '#{prop}'"
            end
          else
            prop = default_token
          end

          prop
        end

        # Value as DATE-TIME or DATE of object of first property with name +name+
        def proptime(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = prop.to_time.first
          end
          prop
        end

        # Value as TEXT of first property with name +name+
        def proptext(name) #:nodoc:
          prop = @properties.detect { |f| f.name? name }
          if prop
            prop = prop.to_text
          end
          prop
        end

        # Array of values as TEXT of all properties with name +name+
        def proptextarray(name) #:nodoc:
          @properties.select{ |f| f.name? name }.map{ |p| p.to_text }
        end

        # Array of values as TEXT list of all properties with name +name+
        def proptextlistarray(name) #:nodoc:
          @properties.select{ |f| f.name? name }.map{ |p| Vpim.decode_text_list(p.value_raw) }.flatten
        end

      end
    end
  end
end

