require "spec_helper"

describe ContentGateway::Cache do
  subject do
    ContentGateway::Cache.new(url, method, params)
  end

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

  describe "#stale_key" do
    let(:url) { "http://example.com" }

    it "should return the stale cache key" do
      expect(subject.stale_key).to eql "stale:http://example.com"
    end
  end
end
