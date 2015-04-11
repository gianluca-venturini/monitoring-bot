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
    a = $applications[application]
    if a['instances'][instance]['components'][component]['alert'] == nil
      a['instances'][instance]['components'][component]['alert'] = []
    end
    if !a['instances'][instance]['components'][component]['alert'].include? mail
      a['instances'][instance]['components'][component]['alert'].push(mail)
    end
    $applications[application] = a
  elsif application != nil && instance != nil
    a = $applications[application]
    if a['instances'][instance]['alert'] == nil
      a['instances'][instance]['alert'] = []
    end
    if !a['instances'][instance]['alert'].include? mail
      a['instances'][instance]['alert'].push(mail)
    end
    $applications[application] = a
  elsif application != nil
    a = $applications[application]
    if a['alert'] == nil
      a['alert'] = []
    end
    emails = a['alert']
    if !emails.include? mail
      emails.push(mail)
    end
    $applications[application] = a
  end

end)

# Listen for published messages
=begin
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
=end

# Add an alert on a specific application/instance/component
nutella.net.subscribe('monitoring/alert/remove', lambda do |message, from|
  puts "Delete alert"
  puts message
  application = message['application']
  instance = message['instance']
  component = message['component']
  mail = message['mail']

  if application != nil && instance != nil && component != nil
    a = $applications[application]
    a['instances'][instance]['components'][component]['alert'] -=[mail]
    $applications[application] = a
  elsif application != nil && instance != nil
    a = $applications[application]
    a['instances'][instance]['alert'] -= [mail]
    $applications[application] = a
  elsif application != nil
    a = $applications[application]
    a['alert'] -= [mail]
    puts a['alert']
    $applications[application] = a
  end
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

  begin
    if application != nil && instance != nil && component != nil
      a = $applications[application]
      alert = a['instances'][instance]['components'][component]['alert']
    elsif application != nil && instance != nil
      a = $applications[application]
      alert = a['instances'][instance]['alert']
    elsif application != nil
      a = $applications[application]
      alert = a['alert']
    end
  rescue
  end

  if alert == nil
    alert = []
  end

  {:emails => alert}
end)

# Create the application structure if it is not present
def create_if_not_present(application, instance, component)

  a = $applications[application]

  if a == nil
    a = {
        :name => application,
        :instances => {}
    }
  end

  begin
    if instance != nil && a['instances'][instance] == nil
      a['instances'][instance] = {
          :name => instance,
          :components => {}
      }
    end
  rescue
    a['instances'][instance] = {
        :name => instance,
        :components => {}
    }
  end

  begin
    if component != nil && instance != nil && a['instances'][instance]['components'][component] == nil
      a['instances'][instance]['components'][component] = {
          :publish => [],
          :subscribe => [],
          :request => [],
          :handle_request => []
      }
    end
  rescue
    a['instances'][instance]['components'][component] = {
        :publish => [],
        :subscribe => [],
        :request => [],
        :handle_request => []
    }
  end

  $applications[application] = a

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
