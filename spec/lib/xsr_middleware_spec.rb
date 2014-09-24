require 'spec_helper'

describe XsrMiddleware do

  let(:app) { ->(env){ [200, {}, ['OK']] } }
  let(:env) {{
    'rack.session.options' => { id: '12345' }
  }}

  subject { XsrMiddleware.new(app) }

  context "when there is no X-TrackingId-header" do
    it "uses the session_id to generate a tracking_id" do
      response = subject.call(env)

      expect(response[1]["X-TrackingId"]).to eql(Digest::MD5.new.hexdigest('12345'))
    end

    it "sets the X-TrackingId-header" do
      response = subject.call(env)

      expect(response[1]["X-TrackingId"]).to match /[a-z0-9]{32}/
    end
  end

  context "when X-TrackingId-header is present" do
    it "doesn't change its value" do
      response = subject.call(env.merge({ 'X-TrackingId' => '57a85d228a17a995a73ab4149c120ef0' }))

      expect(response[1]["X-TrackingId"]).to eql('57a85d228a17a995a73ab4149c120ef0')
    end
  end
end

