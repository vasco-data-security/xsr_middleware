require 'spec_helper'

describe Xsr do

  let(:app) { ->(env){ [200, {}, ['OK']] } }
  let(:env) {{
    'rack.session.options' => { id: '12345' }
  }}

  subject { Xsr::Middleware.new(app) }

  context "when there is no Log-Correlation-ID-header" do
    it "uses the session_id to generate a tracking_id" do
      response = subject.call(env)

      expect(response[1]["Log-Correlation-ID"]).to eql(Digest::MD5.new.hexdigest('12345'))
    end

    it "sets the Log-Correlation-ID-header" do
      response = subject.call(env)

      expect(response[1]["Log-Correlation-ID"]).to match /[a-z0-9]{32}/
    end

    context "when there is no session_id" do
      it "uses an encoded empty string" do
        response = subject.call({})

        expect(response[1]["Log-Correlation-ID"]).to eql(Digest::MD5.new.hexdigest(''))
      end
    end
  end

  context "when Log-Correlation-ID-header is present" do
    it "doesn't change its value" do
      response = subject.call(env.merge({ 'HTTP_LOG_CORRELATION_ID' => '57a85d228a17a995a73ab4149c120ef0' }))

      expect(response[1]["Log-Correlation-ID"]).to eql('57a85d228a17a995a73ab4149c120ef0')
    end
  end
end

