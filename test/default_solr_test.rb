require 'test_helper'
module CDMDEXER
  describe SolrClient do
    let(:client) { Minitest::Mock.new }
    let(:connection) { Minitest::Mock.new }

    it 'establishes a connection' do
      skip('mock not working')
      client.expect :connect, connection, [{url: "http://localhost:8983/solr/blacklight-core"}]
      Solr.new(url: 'http://localhost:8983/solr/blacklight-core', client: client).connection
      client.verify
    end

    it 'persists data to solr' do
      skip('mock not working')
      client.expect :connect, connection, [{url: "http://localhost:8983/solr/blacklight-core"}]
      connection.expect :add, 'blah', [[{id: "3sfsdf"}]]
      connection.expect :commit, nil
      Solr.new(url: 'http://localhost:8983/solr/blacklight-core', client: client).add([{id: "3sfsdf"}])
      client.verify
    end
  end
end
