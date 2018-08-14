require 'spec_helper'

describe Xsr::RequestContext do

  subject { Xsr::RequestContext }

  describe "#correlation_id=" do
    it "adds the correlation id to the Thread" do
      subject.correlation_id = '123456'
      expect(Thread.current['ctx_correlation_id']).to eql '123456'
    end
  end

  describe "#reset_correlation_id!" do
    it "removes the correlation id from the Thread" do
      Thread.current['ctx_correlation_id'] = '1234567890'
      subject.reset_correlation_id!
      expect(Thread.current['ctx_correlation_id']).to be_nil
    end
  end

  describe "#correlation_id" do
    it "returns the correlation id which is stored in the Thread" do
      Thread.current['ctx_correlation_id'] = '1234567890'
      expect(subject.correlation_id).to eql "1234567890"
    end
  end
end
