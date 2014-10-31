require "spec_helper"

describe ContentGateway::Gateway do
  subject do
    ContentGateway::Gateway.new("label", config, url_generator)
  end

  let(:config) { double("config", proxy: nil) }
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:payload) { { "data" => 1234 } }
  let(:url_generator) { double("URL generator") }
  let(:path) { "/api/test.json" }
  let(:cache) { double("cache", use?: false, status: "HIT") }
  let(:request) { double("request", execute: data) }
  let(:data) { '{"param": "value"}' }
  let(:cache_params) { { timeout: 2, expires_in: 30, stale_expires_in: 180, skip_cache: false } }

  before do
    allow(url_generator).to receive(:generate).and_return("url")
  end

  describe "GET method" do
    before do
      expect(ContentGateway::Request).
        to receive(:new).
        with(:get, "url", headers, nil, config.proxy, cache_params).
        and_return(request)
      expect(ContentGateway::Cache).
        to receive(:new).
        with(config, "url", :get, cache_params).
        and_return(cache)
    end

    describe "#get" do
      it "should do a get request passing the correct parameters" do
        expect(subject.get(path, cache_params.merge(headers: headers))).to eql data
      end
    end

    describe "#get_json" do
      it "should parse the response as JSON" do
        expect(subject.get_json(path, cache_params.merge(headers: headers))).to eql JSON.parse(data)
      end
    end
  end

  describe "POST method" do
    before do
      expect(ContentGateway::Request).
        to receive(:new).
        with(:post, "url", nil, payload, config.proxy, cache_params).
        and_return(request)
      expect(ContentGateway::Cache).
        to receive(:new).
        with(config, "url", :post, cache_params).
        and_return(cache)
    end

    describe "#post" do
      it "should do a post request passing the correct parameters" do
        expect(subject.post(path, cache_params.merge(payload: payload))).to eql data
      end
    end

    describe "#post_json" do
      it "should parse the response as JSON" do
        expect(subject.post_json(path, cache_params.merge(payload: payload))).to eql JSON.parse(data)
      end
    end
  end

  describe "PUT method" do
    before do
      expect(ContentGateway::Request).
        to receive(:new).
        with(:put, "url", nil, payload, config.proxy, cache_params).
        and_return(request)
      expect(ContentGateway::Cache).
        to receive(:new).
        with(config, "url", :put, cache_params).
        and_return(cache)
    end

    describe "#put" do
      it "should do a put request passing the correct parameters" do
        expect(subject.put(path, cache_params.merge(payload: payload))).to eql data
      end
    end

    describe "#put_json" do
      it "should parse the response as JSON" do
        expect(subject.put_json(path, cache_params.merge(payload: payload))).to eql JSON.parse(data)
      end
    end
  end

  describe "DELETE method" do
    before do
      expect(ContentGateway::Request).
        to receive(:new).
        with(:delete, "url", nil, payload, config.proxy, cache_params).
        and_return(request)
      expect(ContentGateway::Cache).
        to receive(:new).
        with(config, "url", :delete, cache_params).
        and_return(cache)
    end

    describe "#delete" do
      it "should do a delete request passing the correct parameters" do
        expect(subject.delete(path, cache_params.merge(payload: payload))).to eql data
      end
    end

    describe "#delete_json" do
      it "should parse the response as JSON" do
        expect(subject.delete_json(path, cache_params.merge(payload: payload))).to eql JSON.parse(data)
      end
    end
  end
end
