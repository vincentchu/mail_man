require 'spec_helper'

describe MailMan::Message do

  before(:all) do
    $redis.flushdb

    @mesg_id    = "<4e281ce089fd4_3569e59302151e@ip-10-86-222-44.tmail>"
    @time_int   = Time.now.to_i
    @array_data = ["subject", "subject", "message_id", "an_id", "timestamp", @time_int.to_s]
    
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
      (Time.now.to_i - @message.timestamp.to_i).should be_within(10).of(0)
    end

    it "should initialize from an array" do
      MailMan::Message.new( @array_data ).tap do |mesg|
        mesg.subject.should    == "subject"
        mesg.message_id.should == "an_id"
        mesg.timestamp.should be_an_instance_of(Time)
        mesg.timestamp.to_i.should be_within(10).of(@time_int)
      end
    end
  end

  describe "#save!" do
    describe "when valid" do

      before(:all) do
        @message.save!
      end

      it "should store itself in redis" do
        hash = $redis.hgetall(@message.redis_key)

        hash["subject"].should    == "a subject"
        hash["message_id"].should == @mesg_id
        (Time.now.to_i - hash["timestamp"].to_i).should be_within(10).of(0)
      end

      it "should associate the message with the tags" do
       $redis.lrange("vincentchu@gmail.com", 0, -1).should == [@message.redis_key] 
      end

      it "should increment lifetime_counts" do

        midnight_time = MailMan::Tag::DAY_IN_SECS * (Time.now.to_i / MailMan::Tag::DAY_IN_SECS)

        data = $redis.lindex("lifetime_counter_vincentchu@gmail.com", 0)
        data.should == "#{midnight_time}/1"
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
