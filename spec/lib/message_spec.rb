require 'spec_helper'

describe MailMan::Message do


  before(:all) do
    $redis.flushdb

    @mesg_id = "<4e281ce089fd4_3569e59302151e@ip-10-86-222-44.tmail>"
    @message = MailMan::Message.new(
      :subject    => "a subject",
      :tags       => ["vincentchu@gmail.com"],
      :message_id => @mesg_id   
    )
  end

  describe "#instantiate" do
    it "should instantiate properly with subject, tags, and message_id" do

      @message.subject.should == "a subject"
      @message.tags.should == ["vincentchu@gmail.com"]
      @message.message_id.should == @mesg_id
    end
  end

  describe "#save!" do
    describe "when valid" do

      before(:all) do
        @message.save!
      end

      it "should store itself in redis" do
        $redis.hgetall(@message.redis_key).should == {"subject" => "a subject", "message_id" => @mesg_id}
      end

      it "should associate the message with the tags" do
       $redis.lrange("vincentchu@gmail.com", 0, -1).should == [@message.redis_key] 
      end
    end

    describe "when invalid" do
      it "should raise an exception if message_id or subject aren't set" do
        lambda {
          MailMan::Message.new.save!
        }.should raise_exception( MailMan::Message::MissingFields )
      end
    end
  end
end
