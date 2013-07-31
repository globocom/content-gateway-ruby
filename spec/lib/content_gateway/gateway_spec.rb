# -*- coding: utf-8 -*-

require "spec_helper"

describe ContentGateway::Gateway do
  let! :url_generator do
    url_generator = double('url_generator')
    url_generator.stub(:generate).with(resource_path, {}).and_return("http://api.com/servico")
    url_generator
  end

  let! :config do
    {
      cache: ActiveSupport::Cache::NullStore.new,
      cache_expires_in: 15.minutes,
      cache_stale_expires_in: 1.hour
    }
  end

  let :gateway do
    ContentGateway::Gateway.new config, url_generator
  end

  let :params do
    {"a|b" => 1, name: "a|b|c"}
  end

  let :resource_path do
    "qualquer_coisa"
  end

  let(:timeout) { 0.1 }

  let :cached_response do
    response = "cached response"
    response.instance_eval do
      def code
        200
      end
    end
    response
  end

  before do
    config[:cache].clear
  end

  # describe "#initialize" do
  #   it "deveria aceitar o host como parâmetro" do
  #     novo_host = stub("host")
  #     gateway = ContentGateway::Gateway.new(novo_host)
  #     gateway.instance_variable_get(:@host).should eql novo_host
  #   end

  #   it "deveria assumir um access_token nulo caso não seja passado" do
  #     gateway = ContentGateway::Gateway.new("host")
  #     gateway.instance_variable_get(:@access_token).should be_nil
  #   end

  #   it "deveria aceitar o access_token como parâmetro" do
  #     gateway = ContentGateway::Gateway.new("host", "token")
  #     gateway.instance_variable_get(:@access_token).should eql "token"
  #   end
  # end

  # describe "#generate_url" do
  #   it "deveria gerar a url sem parâmetros" do
  #     gateway.generate_url(resource_path).should eql "#{host}/api/#{resource_path}.json"
  #   end

  #   it "deveria gerar a url com parâmetros" do
  #     gateway.generate_url(resource_path, params).should eql "#{host}/api/#{resource_path}.json?a%7Cb=1&name=a%7Cb%7Cc"
  #   end

  #   describe "quando possuir o access_token configurado" do
  #     let :gateway do
  #       ContentGateway::Gateway.new "host", "token"
  #     end

  #     it "deveria incluir automaticamente" do
  #       gateway.generate_url(resource_path).should eql "#{host}/api/#{resource_path}.json?access_token=token"
  #     end
  #   end
  # end

  describe "#get" do
    let :resource_url do
      url_generator.generate(resource_path, {})
    end

    let :stale_cache_key do
      "stale:#{resource_url}"
    end

    let :default_expires_in do
      config[:cache_expires_in]
    end

    let :default_stale_expires_in do
      config[:cache_stale_expires_in]
    end

    before do
      stub_request method: :get, url: resource_url
    end

    it "deveria realizar o request com http get" do
      gateway.get resource_path
    end

    context "no modo com cache" do
      it "deveria cachear as chamadas" do
        cache_store = double("cache_store")
        cache_store.should_receive(:fetch).with(resource_url, expires_in: default_expires_in)
        config[:cache] = cache_store

        gateway.get resource_path
      end

      it "deveria guardar o cache stale" do
        stub_request(url: resource_url) { cached_response }
   
        cache_store = double("cache_store")
        cache_store.should_receive(:fetch).with(resource_url, expires_in: default_expires_in).and_yield
        cache_store.should_receive(:write).with(stale_cache_key, cached_response, expires_in: default_stale_expires_in)
        config[:cache] = cache_store
   
        gateway.get resource_path
      end

      describe "controle de timeout" do
        before do
          stub_request(method: :get, url: resource_url) {
            sleep(0.3)
          }
        end

        it "deveria aceitar um 'timeout' para sobreescrever o padrão" do
          Timeout.should_receive(:timeout).with(timeout)
          gateway.get resource_path, timeout: timeout
        end

        it "deveria cortar requests que passem do tempo configurado" do
          -> { gateway.get resource_path, timeout: timeout }.should raise_error ContentGateway::TimeoutError
        end

        it "deveria cortar os acessos ao cache que passem do tempo configurado" do
          config[:cache].stub(:fetch) { sleep(1) }
          -> { gateway.get resource_path, timeout: timeout }.should raise_error ContentGateway::TimeoutError
        end
      end

      context "com cache stale" do
        context "timeout" do
          before do
            cache_store = double("cache_store")
            cache_store.stub(:fetch).with(resource_url, expires_in: default_expires_in).and_raise(Timeout::Error)
            cache_store.stub(:read).with(stale_cache_key).and_return(cached_response)
            config[:cache] = cache_store
          end
      
          it "deveria servir stale" do
            gateway.get(resource_path, timeout: timeout).should eql "cached response"
          end
        end

        context "server error" do
          before do
            stub_request_with_error({method: :get, url: resource_url}, RestClient::InternalServerError.new)

            cache_store = double("cache_store")
            cache_store.stub(:fetch).with(resource_url, expires_in: default_expires_in).and_yield
            cache_store.stub(:read).with(stale_cache_key).and_return(cached_response)
            config[:cache] = cache_store
          end

          it "deveria servir stale" do
            gateway.get(resource_path).should eql "cached response"
          end
        end
      end
    end

    context "no modo skip cache" do
      it "deveria não cachear as chamadas" do
        cache_store = double("cache_store")
        cache_store.should_not_receive(:fetch).with(resource_url, expires_in: default_expires_in)
        config[:cache] = cache_store

        gateway.get resource_path, skip_cache: true
      end

      describe "controle de timeout" do
        let(:timeout) { 0.1 }

        before do
          stub_request(method: :get, url: resource_url) {
            sleep(0.3)
          }
        end

        it "deveria ignorar o parâmetro 'timeout'" do
          Timeout.should_not_receive(:timeout).with(timeout)
          gateway.get resource_path, skip_cache: true, timeout: timeout
        end
      end
    end

    it "deveria lançar uma exception de NotFound em caso de 404" do
      stub_request_with_error({method: :get, url: resource_url}, RestClient::ResourceNotFound.new)
      -> { gateway.get resource_path }.should raise_error ContentGateway::ResourceNotFound
    end

    it "deveria lançar um exception de ConnectionFailure em caso de 500" do
      stub_request_with_error({method: :get, url: resource_url}, SocketError.new)
      -> { gateway.get resource_path }.should raise_error ContentGateway::ConnectionFailure
    end

    it "deveria aceitar um 'expires_in' para sobreescrever o padrão" do
      expires_in = 3.minutes
      cache_store = double("cache_store")
      cache_store.should_receive(:fetch).with(resource_url, expires_in: expires_in)
      config[:cache] = cache_store
      gateway.get resource_path, expires_in: expires_in
    end

    it "deveria aceitar um 'stale_expires_in' para sobreescrever o padrão" do
      stub_request(url: resource_url) { cached_response }

      stale_expires_in = 5.minutes
      cache_store = double("cache_store")
      cache_store.stub(:fetch).with(resource_url, expires_in: default_expires_in).and_yield
      cache_store.should_receive(:write).with(stale_cache_key, cached_response, expires_in: stale_expires_in)
      config[:cache] = cache_store

      gateway.get resource_path, stale_expires_in: stale_expires_in
    end
  end

  describe "#get_json" do
    it "deveria converter o resultado do 'get' para JSON" do
      gateway.should_receive(:get).with(resource_path, params).and_return({"a" => 1}.to_json)
      gateway.get_json(resource_path, params).should eql({"a" => 1})
    end
  end

  describe "#post_json" do
    it "deveria converter o resultado do 'post' para JSON" do
      gateway.should_receive(:post).with(resource_path, params).and_return({"a" => 1}.to_json)
      gateway.post_json(resource_path, params).should eql({"a" => 1})
    end
  end

  describe "#put_json" do
    it "deveria converter o resultado do 'put' para JSON" do
      gateway.should_receive(:put).with(resource_path, params).and_return({"a" => 1}.to_json)
      gateway.put_json(resource_path, params).should eql({"a" => 1})
    end
  end

  describe "#post" do
    let :resource_url do
      url_generator.generate(resource_path, {})
    end

    let :payload do
      {param: "value"}
    end

    it "deveria realizar a request com http post" do
      stub_request(method: :post, url: resource_url, payload: payload)
      gateway.post resource_path, payload: payload
    end

    it "deveria lançar uma exception de NotFound em caso de 404" do
      stub_request_with_error({method: :post, url: resource_url, payload: payload}, RestClient::ResourceNotFound.new)
      -> { gateway.post resource_path, payload: payload }.should raise_error ContentGateway::ResourceNotFound
    end

    it "deveria lançar uma exception de UnprocessableEntity em caso de 422" do
      stub_request_with_error({method: :post, url: resource_url, payload: payload}, RestClient::UnprocessableEntity.new)
      -> { gateway.post resource_path, payload: payload }.should raise_error(ContentGateway::ValidationError)
    end

    it "deveria lançar uma exception de Forbidden em caso de 403" do
      stub_request_with_error({method: :post, url: resource_url, payload: payload}, RestClient::Forbidden.new)
      -> { gateway.post resource_path, payload: payload }.should raise_error(ContentGateway::Forbidden)
    end

    it "deveria lançar um exception de ConnectionFailure em caso de 500" do
      stub_request_with_error({method: :post, url: resource_url, payload: payload}, SocketError.new)
      -> { gateway.post resource_path, payload: payload }.should raise_error ContentGateway::ConnectionFailure
    end
  end

  describe "#put" do
    let :resource_url do
      gateway.generate_url(resource_path)
    end

    let :payload do
      {param: "value"}
    end

    it "deveria realizar a request com http put" do
      stub_request(method: :put, url: resource_url, payload: payload)
      gateway.put resource_path, payload: payload
    end

    it "deveria lançar uma exception de NotFound em caso de 404" do
      stub_request_with_error({method: :put, url: resource_url, payload: payload}, RestClient::ResourceNotFound.new)
      -> { gateway.put resource_path, payload: payload }.should raise_error ContentGateway::ResourceNotFound
    end

    it "deveria lançar uma exception de UnprocessableEntity em caso de 422" do
      stub_request_with_error({method: :put, url: resource_url, payload: payload}, RestClient::UnprocessableEntity)
      -> { gateway.put resource_path, payload: payload }.should raise_error ContentGateway::ValidationError
    end

    it "deveria lançar uma exception de Forbidden em caso de 403" do
      stub_request_with_error({method: :put, url: resource_url, payload: payload}, RestClient::Forbidden.new)
      -> { gateway.put resource_path, payload: payload }.should raise_error(ContentGateway::Forbidden)
    end

    it "deveria lançar um exception de ConnectionFailure em caso de 500" do
      stub_request_with_error({method: :put, url: resource_url, payload: payload}, SocketError.new)
      -> { gateway.put resource_path, payload: payload }.should raise_error ContentGateway::ConnectionFailure
    end
  end

  private

  def stub_request opts, payload = {}, &block
    opts = {method: :get, proxy: :none}.merge(opts)

    request = RestClient::Request.new(opts)
    RestClient::Request.stub(:new).with(opts).and_return(request)

    request.stub(:execute) {
      block.call if block_given?
    }

    request
  end

  def stub_request_with_error opts, exc
    opts = {method: :get, proxy: :none}.merge(opts)

    request = RestClient::Request.new(opts)
    RestClient::Request.stub(:new).with(opts).and_return(request)

    request.stub(:execute).and_raise(exc)
  end
end
