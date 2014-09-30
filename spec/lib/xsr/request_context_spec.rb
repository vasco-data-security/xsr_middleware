require 'spec_helper'

describe Xsr::RequestContext do

  subject { Xsr::RequestContext }

  describe "#set_tracking_id" do
    it "adds the tracking id to the Thread" do
      subject.set_tracking_id('123456')
      expect(Thread.current['ctx_tracking_id']).to eql '123456'
    end
  end

  describe "#reset_tracking_id!" do
    it "removes the tracking id from the Thread" do
      Thread.current['ctx_tracking_id'] = '1234567890'
      subject.reset_tracking_id!
      expect(Thread.current['ctx_tracking_id']).to be_nil
    end
  end

  describe "#tracking_id" do
    it "returns the tracking id which is stored in the Thread" do
      Thread.current['ctx_tracking_id'] = '1234567890'
      expect(subject.tracking_id).to eql "1234567890"
    end
  end
end
