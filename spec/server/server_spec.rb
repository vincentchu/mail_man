require 'request_helper'

describe MailMan::Server do
  include Rack::Test::Methods

  def app
    MailMan::Server
  end

  it "should have a root action" do
    get "/"
    last_response.status.should == 200
  end

  describe "Logging a message" do 
    it "should create a message" do
      
      @message = MailMan::Message.new
      @message.should_receive(:save!).once
      MailMan::Message.should_receive(:new).once.and_return(@message)

      post("/message", 
        :subject    => "subject",
        :message_id => "m_id",
        :tags       => ["john@harvard.edu", "mysubs"],
        :timestamp  => "timestamp"
      )

      last_response.status.should == 200
    end

    [:subject, :message_id].each do |attr|
      it "should return 400 if #{attr} is not set" do
        opts = {attr => "mock_#{attr}"}
        post "/message", opts 

        last_response.status.should == 400
      end
    end
  end
end