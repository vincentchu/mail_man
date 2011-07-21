require 'spec_helper'

describe MailMan::Message do

  describe "#instantiate" do
    it "should instantiate properly with subject, tags, and message_id" do
      @message = MailMan::Message.new(
        :subject    => "a subject",
        :tags       => [:tag1, :tag2],
        :message_id => "a_message_id"
      )

      @message.subject.should == "a subject"
      @message.tags.should == [:tag1, :tag2]
      @message.message_id.should == "a_message_id"
    end
  end



end
