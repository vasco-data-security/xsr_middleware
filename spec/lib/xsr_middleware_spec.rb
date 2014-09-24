require 'spec_helper'

describe XsrMiddleware do

  let(:app) { ->(env){ [200, {}, ['OK']] } }
  let(:env) {{
    'rack.session.options' => { id: '12345' }
  }}

  subject { XsrMiddleware.new(app) }

  context "when there is no X-Tracking-Id-header" do
    it "uses the session_id to generate a tracking_id" do
      response = subject.call(env)

      expect(response[1]["X-Tracking-Id"]).to eql(Digest::MD5.new.hexdigest('12345'))
    end

    it "sets the X-Tracking-Id-header" do
      response = subject.call(env)

      expect(response[1]["X-Tracking-Id"]).to match /[a-z0-9]{32}/
    end

    context "when there is no session_id" do
      it "uses an encoded empty string" do
        response = subject.call({})

        expect(response[1]["X-Tracking-Id"]).to eql(Digest::MD5.new.hexdigest(''))
      end
    end
  end

  context "when X-Tracking-Id-header is present" do
    it "doesn't change its value" do
      response = subject.call(env.merge({ 'X-Tracking-Id' => '57a85d228a17a995a73ab4149c120ef0' }))

      expect(response[1]["X-Tracking-Id"]).to eql('57a85d228a17a995a73ab4149c120ef0')
    end
  end
end

