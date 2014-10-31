require "spec_helper"

describe ContentGateway::Cache do
  subject do
    ContentGateway::Cache.new(config, url, method, params)
  end

  let(:config) { OpenStruct.new(cache: cache_store) }

  let(:cache_store) { double("cache store", write: nil) }

  let(:url) { "/url" }

  let(:method) { :get }

  let(:params) { {} }

  describe "#use?" do
    context "when skip_cache is true" do
      let(:params) { { skip_cache: true } }

      it "shouldn't use cache" do
        expect(subject.use?).to eql false
      end
    end

    context "when method isn't get or head" do
      let(:method) { :post }

      it "shouldn't use cache" do
        expect(subject.use?).to eql false
      end
    end

    context "when method is get" do
      let(:method) { :get }

      it "should use cache" do
        expect(subject.use?).to eql true
      end
    end

    context "when method is head" do
      let(:method) { :head }

      it "should use cache" do
        expect(subject.use?).to eql true
      end
    end
  end

  describe "#fetch" do
    let(:request) { double("request", execute: "data") }

    context "when cache hits" do
      before do
        expect(Timeout).to receive(:timeout) do |timeout, &arg|
          arg.call
        end

        expect(cache_store).to receive(:fetch).with(url, expires_in: 100).and_return("cached data")
      end

      it "should return the cached data" do
        expect(subject.fetch(request, expires_in: 100)).to eql "cached data"
      end
    end

    context "when cache misses" do
      context "and request succeeds" do
        before do
          expect(Timeout).to receive(:timeout) do |timeout, &arg|
            arg.call
          end

          expect(cache_store).to receive(:fetch) do |url, params, &arg|
            arg.call
          end
        end

        it "should set status to 'MISS'" do
          subject.fetch(request)

          expect(subject.status).to eql "MISS"
        end

        it "should convert request response into string" do
          expect(String).to receive(:new).with("data")
          subject.fetch(request)
        end

        it "should return the request data" do
          expect(subject.fetch(request)).to eql "data"
        end

        it "should write the request data to stale cache" do
          expect(cache_store).to receive(:write).with("stale:/url", "data", expires_in: 15)

          subject.fetch(request, stale_expires_in: 15)
        end
      end
    end
  end

  describe "#serve_stale" do
    before do
      expect(cache_store).to receive(:read).with("stale:/url").and_return(return_value)
    end

    context "when data are successfully read from stale cache" do
      let(:return_value) { "stale cache data" }

      it "should return the stale data" do
        expect(subject.serve_stale).to eql "stale cache data"
      end

      it "should set status to 'STALE'" do
        subject.serve_stale
        expect(subject.status).to eql "STALE"
      end
    end

    context "when data can't be read from stale cache" do
      let(:return_value) { nil }

      it "should raise ContentGateway::StaleCacheNotAvailableError" do
        expect { subject.serve_stale }.to raise_error ContentGateway::StaleCacheNotAvailableError
      end
    end
  end

  describe "#stale_key" do
    let(:url) { "http://example.com" }

    it "should return the stale cache key" do
      expect(subject.stale_key).to eql "stale:http://example.com"
    end
  end
end
