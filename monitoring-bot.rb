require 'nutella_lib'
require 'json'


# Parse command line arguments
broker, app_id, run_id = nutella.parse_args ARGV
# Extract the component_id
component_id = nutella.extract_component_id
# Initialize nutella
nutella.init(broker, app_id, run_id, component_id)

# Open the resources database
$applications = nutella.persist.get_json_object_store('applications')
$messages = nutella.persist.get_json_object_store('messages')

puts 'Monitoring bot initialization'

# Add an alert on a specific application/instance/component
nutella.net.subscribe('monitoring/alert/add', lambda do |message, from|
  puts message
  application = message['application']
  instance = message['instance']
  component = message['component']
  mail = message['mail']

  create_if_not_present(application, instance, component)

  if application != nil
    puts "Subscribed to #{application} with mail #{mail}";
  end

  if application != nil && instance != nil && component != nil
    if $applications[application]['instances'][instance]['components'][component]['alert'] == nil
      $applications[application]['instances'][instance]['components'][component]['alert'] = []
    end
    $applications[application]['instances'][instance]['components'][component]['alert'].push(mail)
  elsif application != nil && instance != nil
    if $applications[application]['instances'][instance]['alert'] == nil
      $applications[application]['instances'][instance]['alert'] = []
    end
    $applications[application]['instances'][instance]['alert'].push(mail)
  elsif application != nil
    if $applications[application]['alert'] == nil
      $applications[application]['alert'] = []
    end
    $applications[application]['alert'].push(mail)
  end

end)

# Listen for published messages
nutella.net.subscribe('#', lambda do |message, channel, from|
  puts message
  puts channel
  #application = from['app_id']
  #instance = from['run_id']
  #component = from['component_id']
  puts from
  #puts application, instance, component

  #create_if_not_present(application, instance, component)

  #if !($applications[application]['instances'][instance]['components'][component]['publish'].include? channel)
  #  $applications[application]['instances'][instance]['components'][component]['publish'].push(channel)
  #end

end)

# Listen for subscribe
# Listen for request
# Listen for handle_request

# Request the list of alert for an application/instance/component
nutella.net.handle_requests('monitoring/alert', lambda do |request, from|
  puts 'Sending alert list'
  application = request['application']
  instance = request['instance']
  component = request['component']

  alert = nil

  puts $applications['application1']['alert']
  if application != nil && instance != nil && component != nil
    alert = $applications[application]['instances'][instance]['components'][component]['alert']
  elsif application != nil && instance != nil
    alert = $applications[application]['instances'][instance]['alert']
  elsif application != nil
    alert = $applications[application]['alert']
  end


  if alert == nil
    alert = []
  end

  alert
end)

# Create the application structure if it is not present
def create_if_not_present(application, instance, component)
  if $applications[application] == nil
    $applications[application] = {
        :name => application,
        :instances => {}
    }
  end

  if instance != nil && $applications[application]['instances'][instance] == nil
    $applications[application]['instances'][instance] = {
        :name => instance,
        :components => {}
    }
  end

  if component != nil && $applications[application]['instances'][instance]['components'][component] == nil
    $applications[application]['instances'][instance]['components'][component] = {
        :publish => [],
        :subscribe => [],
        :request => [],
        :handle_request => []
    }
  end
end

nutella.net.handle_requests('monitoring/application', lambda do |request, from|
  apps = []
  for key in $applications.keys()
    application = $applications[key]
    apps.push(application)
  end
  {:applications => apps}
end)

nutella.net.handle_requests('monitoring/message', lambda do |request, from|
  reply = $messages['messages']
  {:messages => reply}
end)

puts 'Initialization completed'

# Just sit there waiting for messages to come
nutella.net.listen
