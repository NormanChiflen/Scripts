#http://blog.mattrevell.net/2014/02/19/automatically-remove-dead-autoscale-nodes-from-chef-server/

#!/usr/bin/env ruby
 
require 'fog'
require 'json'
require 'logger'
 
aws_key_id = "{aws key id}"
aws_secret_key = "{aws secret key}"
queue_url = "{sqs queue url}"
 
logger = Logger.new(STDOUT)
logger.level = Logger::INFO
 
sqs = Fog::AWS::SQS.new(
     :aws_access_key_id => aws_key_id,
     :aws_secret_access_key => aws_secret_key,
     :region => "us-east-1"
    )
 
begin
  messages = sqs.receive_message(queue_url, { 'Attributes' => [], 'MaxNumberOfMessages' => 10 }).body['Message']
  unless messages.empty?
    messages.each do |m|
      begin
        body = JSON.parse(m['Body'])
        message = JSON.parse(body["Message"])
      rescue JSON::ParserError => e
        logger.error("Unable to parse JSON object")
        logger.error(e.message)
        next
      end
 
      begin
        if message["Event"].include? "autoscaling:EC2_INSTANCE_TERMINATE"
          instance_id = message["EC2InstanceId"]
          delete_node  = "/usr/local/bin/knife node delete #{instance_id} -y"
          delete_client = "/usr/local/bin/knife client delete #{instance_id} -y"
 
          output = `#{delete_node}`
          result=$?.success?
          if result != true
            logger.error("Failed to delete node #{instance_id}")
            logger.error(output)
          end
 
          output = `#{delete_client}`
          result=$?.success?
          if result != true
            logger.error("Failed to delete client #{instance_id}")
            logger.error(output)
          end
 
          logger.info("Node #{instance_id} deleted successfully")
          sqs.delete_message(queue_url, m['ReceiptHandle'])
        end
      rescue NoMethodError => e
        logger.error(Invalid message in queue")
        logger.error(e.message)
        next
      end
    end
  end
end while ! messages.empty?

