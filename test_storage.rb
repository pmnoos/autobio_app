require 'yaml'
require 'erb'

# Load and test the storage.yml file
storage_config = YAML.load(ERB.new(File.read('config/storage.yml')).result)
puts "Storage config loaded successfully:"
puts storage_config.inspect

# Check if local service is defined
if storage_config['local']
  puts "\nLocal service configuration:"
  puts storage_config['local'].inspect
else
  puts "\nERROR: Local service not found in configuration!"
end
