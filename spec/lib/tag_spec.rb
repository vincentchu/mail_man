require 'spec_helper'

describe MailMan::Tag do

  before(:all) do
    $redis.flushdb
    @address = "john@harvard.edu"
    @tag = MailMan::Tag.new( @address )

    store_many_mesgs_for!(@address)
  end

  describe "#initialize" do
    it "should set its own name" do
      @tag.name.should == @address
    end

    it "should raise an exception if name isn't set" do
      lambda {
        MailMan::Tag.new(nil)
      }.should raise_exception( MailMan::Tag::MissingTagName )
    end
  end 
   
  describe "#summary" do
    before(:all) do

      puts "XXX #{@tag.lifetime_counter}"
      @tag.should_receive(:find).any_number_of_times.and_return(@tag.find)
      @tag.should_receive(:lifetime_counter).any_number_of_times.and_return(@tag.lifetime_counter)

      @summary = @tag.summary
    end

    describe "counts" do
      it "should contain the lifetime counts" do
      end

      it "should contain the average over the past 7 days"

      it "should contain the average over the past 14 days"
    end

    it "should contain the messages" do
      @summary[:messages].should == @tag.find
    end
  end


  describe "#total_entries" do
    it "should find total entries" do
      @tag.total_entries.should == 100
    end
  end

  describe "#lifetime_counter" do
    it "should fetch the total number of requests made against this counter" do
      midnight_time = MailMan::Tag::DAY_IN_SECS * (Time.now.to_i / MailMan::Tag::DAY_IN_SECS)

      @tag.lifetime_counter.first == [Time.at(midnight_time), 100]
    end

    it "should pad the history to ensure that there are #{MailMan::Tag::COUNTER_HISTORY} items" do
      counts = @tag.lifetime_counter
      counts.length.should == 30
    end
  end

  describe "#find" do
    it "should return the first 10 results" do
      results = @tag.find
      results.count.should == 10
      results.each_with_index do |r, i|
        ii = 99-i
        
        r.class.should == MailMan::Message
        r.subject.should == "message_#{ii}"
        r.message_id.should == "<message.id.is.#{ii}@foo.com>"
      end
    end

    it "should allow you to paginate over results" do
      results = @tag.find(:per_page => 20, :page => 5)
      results.count.should == 20
      results.each_with_index do |r, i|
        ii = 19 - i

        r.class.should == MailMan::Message
        r.subject.should == "message_#{ii}"
        r.message_id.should == "<message.id.is.#{ii}@foo.com>"
      end
    end
  end
end
