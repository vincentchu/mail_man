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

  describe "Fetching information about a tag" do
    before(:each) do
      $redis.flushdb

      MailMan::Message.new(:subject => "subj", :message_id => "id", :tags => ["foo"]).save!
      @tag     = MailMan::Tag.new("foo")
      @summary = @tag.summary
      
      MailMan::Tag.should_receive(:new).once.and_return(@tag)
    end

    it "should return 200 if the tag exists" do
      @tag.should_receive(:summary).once.and_return(@summary)

      get "/tags/foo"
      last_response.status.should == 200
    end

    it "should return 404 if the tag doesn't exist" do
      @tag.should_receive(:summary).once.and_raise( MailMan::Tag::NotFound )

      get "/tags/foo"
      last_response.status.should == 404
    end

  end

  describe "Logging a message" do 
    %w(/message messages).each do |endpoint|
      it "should create a message against #{endpoint}" do
        
        @message = MailMan::Message.new
        @message.should_receive(:save!).once
        MailMan::Message.should_receive(:new).once.and_return(@message)

        post(endpoint, 
          "subject"    => "subject",
          "message_id" => "m_id",
          "tags"       => ["john@harvard.edu", "mysubs"],
          "timestamp"  => "timestamp"
        )

        last_response.status.should == 200
      end

      [:subject, :message_id].each do |attr|
        it "should return 400 if #{attr} is not set against #{endpoint}" do
          opts = {attr => "mock_#{attr}"}
          post endpoint, opts 

          last_response.status.should == 400
        end
      end
    end
  end
end
