require_relative 'bundle/bundler/setup'
require 'aws-sdk'
require 'httparty'
require 'json'

config = JSON.parse(File.read('config/config.json'))

ENV.update config

aws_access = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
# create queue subscriber
sqs = Aws::SQS::Client.new(region: ENV['AWS_REGION'], credentials: aws_access)
# get queue URL
queue_url = sqs.get_queue_url(queue_name: 'zmz_scraper_queue').queue_url

amy_poller = Aws::SQS::QueuePoller.new(queue_url)

begin
  amy_poller.poll(wait_time_seconds:nil, idle_timeout:5, skip_delete: true) do |msg|

  # :development, :production
  #url = "http://localhost:3000/api/v2/tours"

  # :production
  url = "http://dynamozmz.herokuapp.com/api/v2/tours"

  param_h = { country: msg.body }
  options = { body: param_h.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }}

  results = HTTParty.post(url, options)

  puts results.code

  end
rescue Aws::SQS::Errors::ServiceError => e
  puts "Blame it on the rain: #{e}"
end
