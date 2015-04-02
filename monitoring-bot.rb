require 'nutella_lib'
require 'json'


# Initialize nutella
nutella.init("crepe", "localhost", "monitoring-bot")

# Open the resources database
applications = nutella.persist.getJsonStore("db/applications.json")

puts "Monitoring bot initialization"

# Create new beacon
nutella.net.subscribe("monitoring/alert/add", lambda do |message, component_id, resource_id|
  puts message
  application = message["application"]
  instance = message["instance"]
  component = message["component"]
  mail = message["mail"]

  if application != nil
    puts "Subscribed to #{application} with mail #{mail}";
  end
end)

puts "Initialization completed"

# Just sit there waiting for messages to come
nutella.net.listen
