#
# Filename: tabbed_file_to_vcards.rb
# Author:   Dane G. Avilla
# Description:
# This script takes a tab-delimited text file with address info and attempts 
# to parse each
# line of the file into a VCard. 
#
# Usage: ruby tabbed_file_to_vcards.rb ./contacts.txt > vcards.vcf
#
# This command will create vcards and save them into vcards.vcf.
#
# License: Same as Ruby.
#

require 'vpim/vcard'

#
# Opens a file and attempts to parse out vcards.  It is meant to work on a 
# tab-delimited file with column names in the first line, followed by 
# any number of records on the following lines.
#
class VCardParser

	#
	# Pass in a filename as a string, and get an array of VCard objects back.
	#
	def vcards_from_txt_file(filename)
		#puts "Parsing input file #{filename}"
		vcards = []
		first_line = true
		VCardField.reset_custom_fields
		IO.foreach(filename) { |line|
			#puts "Parsing line: #{line}"
			if first_line == true 
				@headers = headers_from_line(line)
				first_line = false
			else
				vcards << vcard_from_line(line)
			end
		}
		vcards
	end
	
protected
	def headers_from_line(a_line)
		a_line.upcase.split("\t")
	end

	def fields_from_line(a_line)
		field_arr = headers_from_line(a_line)
		fields = {}
		@headers.each_index { |index|
			fields[@headers[index]]= field_arr[index]
		}
		fields
	end
	
	def vcard_from_line(a_line)
		#puts "vcard_from_line"
		# Parse the line from a tab-delimited text file.  
		# The tricky part is that there may
		# be fields in the txt file which have commas between opening and closing
		# quotes, so don't just split on ','.
		
		# Get a hash of field names and values
		fields = fields_from_line(a_line)
		#puts "FirstName: " + fields["FIRST_NAME"]
		# 1. Look for the pattern /\".*,.*\"/
			# 2. If found, save that pattern, and then substitute it with a 
			#    dynamic placeholder.
			
			# 3. Split the line on commas.
			
			# 4. For each item in the split, replace the substituted pattern
			#    with the source pattern.
		
		#p fields
		
		# At this point, we should have an array of string values matching 
		# the order of @headers.  Construct a VCard using the header keys and
		# the parsed values
		vcard = Vpim::Vcard.create

		# Add the name field
		vcard << VCardField.create_n(fields["LAST_NAME"], fields["FIRST_NAME"],
			fields["MIDDLE_NAME"], fields["TITLE"], fields["SUFFIX"])
		# Add the formal name display field
		vcard << VCardField.create_fn(fields["LAST_NAME"], fields["FIRST_NAME"],
			fields["MIDDLE_NAME"], fields["TITLE"], fields["SUFFIX"])
		# Add Company & Department info
		vcard << VCardField.create_org(fields["COMPANY"], fields["DEPARTMENT"])
		# Add Job Title info
		vcard << VCardField.create_job_title(fields["JOB_TITLE"])
		# Add Phone Numbers
		vcard << VCardField.create_work_fax(fields["BUSINESS_FAX"])
		vcard << VCardField.create_work_phone(fields["BUSINESS_PHONE"])
		vcard << VCardField.create_work_phone(fields["BUSINESS_PHONE_2"])
		vcard << VCardField.create_home_fax(fields["HOME_FAX"])
		vcard << VCardField.create_home_phone(fields["HOME_PHONE"])
		vcard << VCardField.create_home_phone(fields["HOME_PHONE_2"])
		vcard << VCardField.create_cell_phone(fields["MOBILE_PHONE"])
		vcard << VCardField.create_pager(fields["PAGER"])
		vcard << VCardField.create_custom_phone(fields["OTHER_PHONE"], "other")
		# Add Business Address
		vcard << VCardField.create_business_address(
			fields["BUSINESS_STREET"],
			fields["BUSINESS_STREET_2"],
			fields["BUSINESS_STREET_3"],
			fields["BUSINESS_CITY"],
			fields["BUSINESS_STATE"],
			fields["BUSINESS_POSTAL_CODE"],
			fields["BUSINESS_COUNTRY"]
			)
		# Add Home Address
		vcard << VCardField.create_home_address(
			fields["HOME_STREET"],
			fields["HOME_STREET_2"],
			fields["HOME_STREET_3"],
			fields["HOME_CITY"],
			fields["HOME_STATE"],
			fields["HOME_POSTAL_CODE"],
			fields["HOME_COUNTRY"]
			)
		# Add Other Address
		vcard << VCardField.create_other_address(
			"Sample Other Address",
			fields["OTHER_STREET"],
			fields["OTHER_STREET_2"],
			fields["OTHER_STREET_3"],
			fields["OTHER_CITY"],
			fields["OTHER_STATE"],
			fields["OTHER_POSTAL_CODE"],
			fields["OTHER_COUNTRY"]
			)
		
		# Add Emails
		vcard << VCardField.create_work_email(fields["E-MAIL_ADDRESS"])
		vcard << VCardField.create_home_email(fields["E-MAIL_2_ADDRESS"])
		vcard << VCardField.create_other_email(fields["E-MAIL_3_ADDRESS"], "other")

		# Add a note
		vcard << VCardField.create_note(fields["NOTES"])

		vcard
	end
end

#
# Subclass of Vpim::DirectoryInfo::Field adds a number of helpful methods for
# creating VCard fields.
#
class VCardField < Vpim::DirectoryInfo::Field
	def VCardField.reset_custom_fields
		@@custom_number = 1
	end
	
	#
	# Create a name field: "N"
	#
	def VCardField.create_n (last, first=nil, middle=nil, prefix=nil, suffix=nil)
		VCardField.create('N', "#{last};#{first};#{middle};#{prefix};#{suffix}")
	end
	
protected
	def VCardField.valid_string(a_str)
		return a_str != nil && a_str.length > 0
	end

public
	
	#
	# Create a formal name field: "FN"
	#
	def VCardField.create_fn (last, first=nil, middle=nil, prefix=nil, suffix=nil)
		name = ""
		if valid_string(prefix)  then name << "#{prefix} "  end
		if valid_string(first)   then name << "#{first} "   end
		if valid_string(middle)  then name << "#{middle} "  end
		if valid_string(last)    then name << "#{last} "    end
		if valid_string(suffix)  then name << "#{suffix} "  end
		VCardField.create('FN', "#{name}")
	end

	#
	# Create a formal name field: "ORG"
	#
	def VCardField.create_org (organization_name, department_name=nil)
		VCardField.create("ORG", "#{organization_name};#{department_name}")
	end

	#
	# Create a title field: "TITLE"
	#
	def VCardField.create_job_title(title)
		VCardField.create("TITLE", title)
	end
	
	#
	# Create an email field: "EMAIL" with type="INTERNET"
	#
	# For _type_, use Ruby symbols :WORK or :HOME.
	#
	def VCardField.create_internet_email(address, type=:WORK, preferred_email=false)
		if preferred_email == true
			VCardField.create("EMAIL", address, 
				"type" => ["INTERNET", type.to_s, "pref"])
		else
			VCardField.create("EMAIL", address,
				"type" => ["INTERNET", type.to_s])
		end
	end

protected
	def VCardField.next_custom_name
		name = "item#{@@custom_number}"
		@@custom_number = @@custom_number + 1
		name
	end

	def VCardField.create_phone(phone_num, is_preferred = false, type_arr = ["WORK"],
		custom_name = nil)

		field_name = ""
		if custom_name != nil
			field_name << next_custom_name
			field_name << "."
		end
		
		# Flatten the array so we can add additional items to it.
		type_arr = [type_arr].flatten
		# If this phone number is preferred, then add that into the type array.
		if is_preferred 
			type_arr << "pref" 
		end
		# Create the TEL field.
		ret_val = [VCardField.create("#{field_name}TEL", phone_num, "type" => type_arr)]
		# If we need a custom field . . .
		if custom_name != nil
			ret_val << VCardField.create("#{field_name}X-ABLabel", custom_name)
		end
		ret_val
	end

public
	def VCardField.create_note(note_text)
		VCardField.create("NOTE", note_text)
	end
	
	def VCardField.create_custom_phone(phone_number, custom_name, is_preferred = false)
		VCardField.create_phone(phone_number, is_preferred, ["HOME"], custom_name)
	end
	
	def VCardField.create_pager(pager_number, is_preferred = false)
		VCardField.create_phone(pager_number, is_preferred, ["PAGER"])
	end
	
	def VCardField.create_work_fax(fax_number, is_preferred = false)
		VCardField.create_phone(fax_number, is_preferred, ["FAX", "WORK"])
	end
	
	def VCardField.create_work_phone(phone_number, is_preferred = false)
		VCardField.create_phone(phone_number, is_preferred, ["WORK"])
	end
	
	def VCardField.create_home_fax(fax_number, is_preferred = false)
		VCardField.create_phone(fax_number, is_preferred, ["FAX", "HOME"])
	end
	
	def VCardField.create_home_phone(phone_number, is_preferred = false)
		VCardField.create_phone(phone_number, is_preferred, ["HOME"])
	end
	
	def VCardField.create_cell_phone(phone_number, is_preferred = false)
		VCardField.create_phone(phone_number, is_preferred, ["CELL"])
	end

	def VCardField.create_other_address(
		address_label,
		street,
		street2 = "",
		street3 = "",
		city = "",
		state = "",
		postal_code = "",
		country = "",
		is_preferred = false
		)
		VCardField.create_address(street, street2, street3, city, state,
			postal_code, country, is_preferred, ["HOME"], address_label)
	end
	
	def VCardField.create_home_address(
		street,
		street2 = "",
		street3 = "",
		city = "",
		state = "",
		postal_code = "",
		country = "",
		is_preferred = false
		)
		VCardField.create_address(street, street2, street3, city, state,
			postal_code, country, is_preferred, ["HOME"])
	end
	
	def VCardField.create_business_address(
		street,
		street2 = "",
		street3 = "",
		city = "",
		state = "",
		postal_code = "",
		country = "",
		is_preferred = false
		)
		VCardField.create_address(street, street2, street3, city, state,
			postal_code, country, is_preferred, ["WORK"])
	end
	
	def VCardField.create_work_email(address, is_preferred = false)
		VCardField.create_email(address, is_preferred, ["WORK"])
	end

	def VCardField.create_home_email(address, is_preferred = false)
		VCardField.create_email(address, is_preferred, ["HOME"])
	end
	
	def VCardField.create_other_email(address, custom_name, is_preferred = false)
		VCardField.create_email(address, is_preferred, ["WORK"], custom_name)
	end

protected
	def VCardField.create_email(address, is_preferred, type_arr = ["WORK"], custom_name = nil)
		name = ""
		if custom_name != nil
			name << next_custom_name
			name << "."
		end
		if is_preferred
			type_arr << "pref"
		end
		ret_val = [VCardField.create("#{name}EMAIL", address, "type" => type_arr)]
		if custom_name != nil
			ret_val << VCardField.create("#{name}X-ABLabel", custom_name)
		end
		ret_val
	end
	
	def VCardField.create_address(
		street,
		street2 = "",
		street3 = "",
		city = "",
		state = "",
		postal_code = "",
		country = "",
		is_preferred = false,
		type_arr = ["WORK"],
		other_label = nil)
		# Addresses need custom names, so get the next custom name for this 
		# VCard
		name = next_custom_name
		# Construct the address string by making an array of the fields, and
		# then joining them with ';' as the separator.
		address_str = [street, street2, street3, city, state, postal_code, country]
		# If this is preferred, add that type.
		if is_preferred
			type_arr << "pref"
		end
		# Return an array with two lines, one defining the address, the second
		# defining something else . . . is this the locale?  Not sure, but this
		# is how Mac OS X 10.3.6 exports address fields -> VCards.
		fields = [
			VCardField.create("#{name}.ADR", address_str.join(';'), "type" => type_arr),
			VCardField.create("#{name}.X-ABADR", "us"),
		]
		if other_label != nil
			fields << VCardField.create("#{name}.X-ABLabel", "#{other_label}")
		end
		fields
	end
end

parser = VCardParser.new
cards = parser.vcards_from_txt_file(ARGV[0])
#puts ""
cards.each { |card|
	puts card.to_s
}
