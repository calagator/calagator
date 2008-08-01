require 'facets/instantise'

class String

  # Style a string. This method routes to the Style module.
  #
  # Examples
  #   "super_man".style:camelcase  #=> "SuperMan"
  #   "SuperMan".style:underscore  #=> "super_man"

  def style(*formats)
    formats.inject(self) do |string, format|
      Style.__send__(format, string)
    end
  end

  # Stlyist module provides an extensible means of applying 
  # common alteration patterns to strings. This library is likely to evolve
  # a great deal. For now it borrows most of it's styles from Rails Inflector
  # library.
  #
  # This module is used by the string/style extension.
  #
  # Examples
  #   String::Style.snakecase("SuperMan")    #=> "super_man"
  #   String::Style.dasherize("super_man")   #=> "super-man"
  #
  # TODO: With #pathize, is downcasing really needed? After all paths can have capitalize letters ;p
  # TODO: With #methodize, is downcasing any but the first letter really needed? Desipite Matz prefernce methods can have capitalized letters.

  module Style

    include Instantise

    private *instance_methods.select{ |a| a !~ /^__|instance_|object_|send/ }

    # Standard downcase style.
    #
    def self.downcase(string)
      string.downcase
    end

    # Same as downcase style.
    #
    def self.lowercase(string)
      string.downcase
    end

    # Standard upcase style.
    #
    def self.upcase(string)
      string.upcase
    end

    # Same as upcase style.
    #
    def self.uppercase(string)
      string.upcase
    end

    # Standard capitalize style.

    def self.capitalize(string)
      string.capitalize
    end

    # Titlecase
    #
    #   "this is a string".style(:titlecase)
    #   => "This Is A String"
    #
    def self.titlecase(phrase)
      phrase.gsub(/\b\w/){$&.upcase}
    end

    # The reverse of +camelize+. Makes an underscored form from the expression in the string.
    #
    # Changes '::' to '/' to convert namespaces to paths.
    #
    # Examples
    #   "ActiveRecord".underscore #=> "active_record"
    #   "ActiveRecord::Errors".underscore #=> active_record/errors

    def self.snakecase(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    # Converts a string into a unix path.
    # This method is geared toward code reflection.
    #
    # See : String#modulize, String#methodize
    #
    #   Style.pathize("MyModule::MyClass")    #=> my_module/my_class
    #   Style.pathize("my_module__my_class")  #=> my_module/my_class
    #
    # TODO:
    #   * Make sure that all scenarios return a valid unix path
    #   * Make sure it is revertible
    #
    # See also #modulize, #methodize

    def self.pathize(module_name)
      module_name.to_s.
      gsub(/__/, '/').
      gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    # Converts a module name into a valid method name
    # This method is geared toward code reflection.
    #
    # Examples
    #   Style.methodize("SuperMan")          #=> "super_man"
    #   Style.methodize("SuperMan::Errors")  #=> "super_man__errors
    #   Style.methodize("MyModule::MyClass") #=> "my_module__my_class"
    #
    # See also #modulize, #pathize

    def self.methodize(module_name)
      module_name.to_s.
      gsub(/\//, '__').
      gsub(/::/, '__').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end

    # Converts a string into a valid ruby class or module name
    # This method is geared toward code reflection.
    #
    # Examples
    #   Style.modulize("camel_case")          #=> "CamelCase"
    #   Style.modulize("camel/case")          #=> "Camel::Case"
    #   Style.modulize("my_module__my_path")  #=> "MyModule::MyPath"
    #
    # See also #methodize, #pathize

    def self.modulize(pathized_or_methodized_string)
      pathized_or_methodized_string.
        gsub(/__(.?)/){ "::#{$1.upcase}" }.
        gsub(/\/(.?)/){ "::#{$1.upcase}" }.
        gsub(/(?:_+)([a-z])/){ $1.upcase }.
        gsub(/(^|\s+)([a-z])/){ $1 + $2.upcase }
    end

    def self.lowercamel(snakecase_word)
      snakecase_word.first + camelize(lower_case_and_underscored_word)[1..-1]
    end

    def self.uppercamel(snakecase_word)
      snakecase_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    ##################
    # ACTIVE SUPPORT #
    #######################################################################
    # These were extracted directly from ActiveSupport's Inflector class. #
    # It seemed prudent to maintian this desgree of compatbility.         #
    #######################################################################

    # By default, camelize converts strings to UpperCamelCase. If the argument to camelize
    # is set to ":lower" then camelize produces lowerCamelCase.
    #
    # camelize will also convert '/' to '::' which is useful for converting paths to namespaces
    #
    # Examples
    #   Style.camelize("active_record")               #=> "ActiveRecord"
    #   Style.caemlize("active_record", true)         #=> "activeRecord"
    #   Style.camelize("active_record/errors")        #=> "ActiveRecord::Errors"
    #   Style.camelize("active_record/errors",true)   #=> "activeRecord::Errors"
    #
    def self.camelize(snakecase_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        snakecase_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        snakecase_word.first + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end

    #def camelize(first_letter_in_uppercase = true)
    #  Style.camelize(self, first_letter_in_uppercase)
    #end

    # Capitalizes all the words and replaces some characters in the string to create
    # a nicer looking title. Titleize is meant for creating pretty output. It is not
    # used in the Rails internals.
    #
    # titleize is also aliased as as titlecase
    #
    # Examples
    #   "man from the boondocks".titleize #=> "Man From The Boondocks"
    #   "x-men: the last stand".titleize #=> "X Men: The Last Stand"

    def self.titleize(word)
      humanize(underscore(word)).gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    # The reverse of +camelize+. Makes an underscored, lowercase form from the expression in the string.
    #
    # Changes '::' to '/' to convert namespaces to paths.
    #
    # Examples
    #   "ActiveRecord".underscore #=> "active_record"
    #   "ActiveRecord::Errors".underscore #=> active_record/errors
    def self.underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    # Replaces underscores with dashes in the string.
    #
    # Example
    #   dasherize("puni_puni") #=> "puni-puni"
    def self.dasherize(underscored_word)
      underscored_word.gsub(/_/, '-')
    end

    # Capitalizes the first word and turns underscores into spaces and strips _id.
    # Like titleize, this is meant for creating pretty output.
    #
    # Examples
    #   "employee_salary" #=> "Employee salary"
    #   "author_id" #=> "Author"
    def self.humanize(lower_case_and_underscored_word)
      lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
    end

    # Removes the module part from the expression in the string
    #
    # Examples
    #   "ActiveRecord::CoreExtensions::String::Inflections".demodulize #=> "Inflections"
    #   "Inflections".demodulize #=> "Inflections"
    def self.demodulize(class_name_in_module)
      class_name_in_module.to_s.gsub(/^.*::/, '')
    end

    # Create the name of a table like Rails does for models to table names. This method
    # uses the pluralize method on the last word in the string.
    #
    # Examples
    #   "RawScaledScorer".tableize #=> "raw_scaled_scorers"
    #   "egg_and_ham".tableize #=> "egg_and_hams"
    #   "fancyCategory".tableize #=> "fancy_categories"
    def self.tableize(class_name)
      pluralize(underscore(class_name))
    end

    # Create a class name from a plural table name like Rails does for table names to models.
    # Note that this returns a string and not a Class. (To convert to an actual class
    # follow classify with constantize.)
    #
    # Examples
    #   "egg_and_hams".classify #=> "EggAndHam"
    #   "posts".classify #=> "Post"
    #
    # Singular names are not handled correctly
    #   "business".classify #=> "Busines"
    def self.classify(table_name)
      # strip out any leading schema name
      camelize(singularize(table_name.to_s.sub(/.*\./, '')))
    end

    # Creates a foreign key name from a class name.
    # +separate_class_name_and_id_with_underscore+ sets whether
    # the method should put '_' between the name and 'id'.
    #
    # Examples
    #   "Message".foreign_key #=> "message_id"
    #   "Message".foreign_key(false) #=> "messageid"
    #   "Admin::Post".foreign_key #=> "post_id"
    def self.foreign_key(class_name, separate_class_name_and_id_with_underscore = true)
      underscore(demodulize(class_name)) + (separate_class_name_and_id_with_underscore ? "_id" : "id")
    end

    # Ordinalize turns a number into an ordinal string used to denote the
    # position in an ordered sequence such as 1st, 2nd, 3rd, 4th.
    #
    # Examples
    #   ordinalize('1')     # => "1st"
    #   ordinalize('2')     # => "2nd"
    #   ordinalize('1002')  # => "1002nd"
    #   ordinalize('1003')  # => "1003rd"
    def self.ordinalize(number_string)
      if number_string =~ /\d{1,2}$/
        number = $1.to_i     
        if (11..13).include?(number.to_i % 100)
          r = "#{number}th"
        else
          r = case number.to_i % 10
            when 1; "#{number}st"
            when 2; "#{number}nd"
            when 3; "#{number}rd"
            else    "#{number}th"
          end
        end
        number_string.sub(/\d{1,2}$/, r)
      else
        number_string
      end
    end

  end

end

