require 'nutella_lib'
require 'json'


# Initialize nutella
nutella.init("crepe", "localhost", "monitoring-bot")

# Open the resources database
$applications = nutella.persist.getJsonStore('db/applications.json')

puts 'Monitoring bot initialization'

# Add an alert on a specific application/instance/component
nutella.net.subscribe('monitoring/alert/add', lambda do |message, component_id, resource_id|
  puts message
  application = message['application']
  instance = message['instance']
  component = message['component']
  mail = message['mail']

  create_if_not_present(application, instance, component)

  if application != nil
    puts "Subscribed to #{application} with mail #{mail}";
  end

  $applications.transaction{
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
  }

end)

# Listen for published messages
nutella.net.subscribe('#', lambda do |message, channel, component_id, resource_id|
  puts message
  puts channel
  application = 'application1'
  instance = 'instance1'
  component = 'component1'

  create_if_not_present(application, instance, component)

  $applications.transaction{
    if !($applications[application]['instances'][instance]['components'][component]['publish'].include? channel)
      $applications[application]['instances'][instance]['components'][component]['publish'].push(channel)
    end
  }
end)

# Request the list of alert for an application/instance/component
nutella.net.handle_requests('monitoring/alert', lambda do |request, component_id, resource_id|
  puts 'Sending alert list'
  application = request['application']
  instance = request['instance']
  component = request['component']

  alert = nil

  $applications.transaction {
    puts $applications['application1']['alert']
    if application != nil && instance != nil && component != nil
      alert = $applications[application]['instances'][instance]['components'][component]['alert']
    elsif application != nil && instance != nil
      alert = $applications[application]['instances'][instance]['alert']
    elsif application != nil
      alert = $applications[application]['alert']
    end
  }

  if alert == nil
    alert = []
  end

  alert
end)

# Create the application structure if it is not present
def create_if_not_present(application, instance, component)
  $applications.transaction {
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
  }
end

puts 'Initialization completed'

# Just sit there waiting for messages to come
nutella.net.listen
