# Read config/database.yml into a datastructure

require 'lib/database_yml_reader'
$database_yml_struct ||= DatabaseYmlReader.read
