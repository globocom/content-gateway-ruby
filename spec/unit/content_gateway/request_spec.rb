require "spec_helper"

describe ContentGateway::Request do
  subject do
    ContentGateway::Request.new(:get, "/url")
  end

  before do
    allow(RestClient::Request).to receive(:new).with(request_params).and_return(client)
  end

  let(:client) { double("rest client", execute: "data", url: "/url") }

  let(:request_params) { { method: :get, url: "/url", proxy: :none } }

  describe "#execute" do
    context "when request is successful" do
      it "should return request data" do
        expect(subject.execute).to eql "data"
      end
    end

    context "when request fails" do
      context "with RestClient::ResourceNotFound exception" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::ResourceNotFound)
        end

        it "should raise ContentGateway::ResourceNotFound" do
          expect { subject.execute }.to raise_error ContentGateway::ResourceNotFound
        end
      end

      context "with RestClient::Unauthorized exception" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::Unauthorized)
        end

        it "should raise ContentGateway::UnauthorizedError" do
          expect { subject.execute }.to raise_error ContentGateway::UnauthorizedError
        end
      end

      context "with RestClient::UnprocessableEntity exception" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::UnprocessableEntity)
        end

        it "should raise ContentGateway::ValidationError" do
          expect { subject.execute }.to raise_error ContentGateway::ValidationError
        end
      end

      context "with RestClient::Forbidden exception" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::Forbidden)
        end

        it "should raise ContentGateway::Forbidden" do
          expect { subject.execute }.to raise_error ContentGateway::Forbidden
        end
      end

      context "with RestClient::Conflict exception" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::Conflict)
        end

        it "should raise ContentGateway::ConflictError" do
          expect { subject.execute }.to raise_error ContentGateway::ConflictError
        end
      end

      context "with a 5xx error" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::Exception.new(nil, 502))
        end

        it "should raise ContentGateway::ServerError" do
          expect { subject.execute }.to raise_error ContentGateway::ServerError
        end
      end

      context "with other error codes from RestClient" do
        before do
          expect(client).to receive(:execute).and_raise(RestClient::Exception.new(nil, 418))
        end

        it "should raise the original exception" do
          expect { subject.execute }.to raise_error RestClient::Exception
        end
      end

      context "with unmapped exceptions" do
        before do
          expect(client).to receive(:execute).and_raise(StandardError)
        end

        it "should raise ContentGateway::ConnectionFailure" do
          expect { subject.execute }.to raise_error ContentGateway::ConnectionFailure
        end
      end
    end

    context "requests with SSL" do

      let(:ssl_certificate_params) { { ssl_client_cert: "test", ssl_client_key: "test", ssl_version: "SSLv23"} }
      let(:restclient_ssl_params) { { ssl_client_cert: "cert", ssl_client_key: "key", verify_ssl: 0, ssl_version: "SSLv23" } }
      let(:request_params_ssl) { request_params.merge! restclient_ssl_params }

      let :subject_ssl do
        ContentGateway::Request.new(:get, "/url", {}, {}, nil, ssl_certificate: ssl_certificate_params)
      end

      context "only with ssl version" do
        let(:ssl_certificate_params) { { ssl_version: "SSLv23" } }
        let(:restclient_ssl_params) { { ssl_version: "SSLv23" } }
        let(:request_params_ssl) { request_params.merge! restclient_ssl_params }

        it "should setup request with ssl version" do
          expect(RestClient::Request).to receive(:new).with(request_params_ssl)
          subject_ssl.execute
        end

        it "should not setup ssl certificates" do
          allow(RestClient::Request).to receive(:new).with(request_params_ssl).and_return(client)
          expect(OpenSSL::X509::Certificate).to_not receive(:new)
          expect(OpenSSL::PKey::RSA).to_not receive(:new)
          subject_ssl.execute
        end
      end

      context "when request is successful" do
        before do
          allow(File).to receive(:read).with("test").and_return("cert_content")
          allow(OpenSSL::X509::Certificate).to receive(:new).with("cert_content").and_return("cert")
          allow(OpenSSL::PKey::RSA).to receive(:new).with("cert_content").and_return("key")
          allow(RestClient::Request).to receive(:new).with(request_params_ssl).and_return(client)
        end

        it "should setup ssl certificates" do
          expect(OpenSSL::X509::Certificate).to receive(:new).with("cert_content")
          expect(OpenSSL::PKey::RSA).to receive(:new).with("cert_content")
          subject_ssl.execute
        end

        it "should setup request with ssl params" do
          expect(RestClient::Request).to receive(:new).with(request_params_ssl)
          subject_ssl.execute
        end

        it "should return request data with ssl params" do
          expect(subject_ssl.execute).to eql "data"
        end
      end

      context "when request fails" do
        it "should return ssl failure error if certificate was not found" do
          expect { subject_ssl.execute }.to raise_error(ContentGateway::OpenSSLFailure).with_message(/^\/url - No such file or directory/)
        end

        it "should return ssl failure error if certificate cert was not valid" do
          allow(File).to receive(:read).with("test").and_return("cert_content")
          expect { subject_ssl.execute }.to raise_error(ContentGateway::OpenSSLFailure).with_message("/url - not enough data - invalid ssl client cert")
        end

        it "should return ssl failure error if certificate key was not valid" do
          allow(File).to receive(:read).with("test").and_return("cert_content")
          allow(OpenSSL::X509::Certificate).to receive(:new).with("cert_content").and_return("cert")
          expect { subject_ssl.execute }.to raise_error(ContentGateway::OpenSSLFailure).with_message("/url - Neither PUB key nor PRIV key: not enough data - invalid ssl client key")
        end
      end
    end

    context "when proxy is used" do
      let(:proxy) { 'http://proxy.test:3128' }
      subject { ContentGateway::Request.new(:get, "/url", {}, {}, proxy) }
      let(:request_params) { { method: :get, url: "/url", proxy: proxy } }

      it "should set proxy on RestClient" do
        expect(subject.execute).to eql "data"
        expect(RestClient.proxy).to eql(proxy)
      end
    end

  end
end
