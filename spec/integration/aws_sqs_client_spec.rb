require 'spec_helper'
require 'digest'

class TestJob < ActiveJob::Base
  queue_as :high_priority

  def perform(test_arg)
    test_arg
  end
end

describe Aws::SQS::Client do
  subject(:aws_client)  { aws_sqs_client}

  it "is configured with valid credentials and region" do
    expect { aws_client.list_queues }.to_not raise_error
  end

  describe "message dispatching" do
    let(:queue_name) { "ActiveElasticJob-integration-testing" }
    let(:queue_url) do
      response = aws_client.create_queue(queue_name: queue_name)
      response.queue_url
    end
    let(:message_content) { JSON.dump(TestJob.new.serialize) }
    let(:md5_digest) { Digest::MD5.hexdigest(message_content) }

    describe "#send_message" do
      it "is successful" do
        response = aws_client.send_message(
          message_body: message_content,
          queue_url: queue_url
        )

        expect(response.md5_of_message_body).to match(md5_digest)
      end
    end
  end
end
