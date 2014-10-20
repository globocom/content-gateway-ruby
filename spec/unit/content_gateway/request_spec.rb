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
  end
end
