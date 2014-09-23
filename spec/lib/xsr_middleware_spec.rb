require 'spec_helper'

describe XsrMiddleware do

  let(:app) { ->(env){ [200, {}, ['OK']] } }
  let(:env) {{
    'rack.session.options' => { id: '12345' }
  }}

  subject { XsrMiddleware.new(app) }

  context "when there is no X-TrackingId-header" do
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

  context "when cookie is set" do
    it "doesn't change its value" do
      response = subject.call(
        env.merge({ 'rack.request.cookie_hash' => { '_dpplus_xsr_id' => '022f43b5303c0ebccd95b8fe9ccb6b44' }})
      )

      expect(response[1]["Set-Cookie"]).to eql("_dpplus_xsr_id=022f43b5303c0ebccd95b8fe9ccb6b44; path=/")
    end
  end

  context "when cookie is not set" do
    it "sets the cookie" do
      response = subject.call(env)

      expect(response[1]["Set-Cookie"]).to match(/_dpplus_xsr_id=[a-z0-9]{32}; path=\//)
    end
  end

  context "when tracking_id gets reset by the app using the middleware" do
    it "deletes the cookie" do
      allow(XsrMiddleware::RequestContext).to receive(:tracking_id).and_return(nil)

      response = subject.call(
        env.merge({ 'rack.request.cookie_hash' => { '_dpplus_xsr_id' => '022f43b5303c0ebccd95b8fe9ccb6b44' }})
      )

      expect(response[1]["Set-Cookie"]).not_to match(/_dpplus_xsr_id=[a-z0-9]{32}; path=\//)
    end
  end
end

