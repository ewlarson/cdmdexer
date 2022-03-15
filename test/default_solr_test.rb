# frozen_string_literal: true

require 'test_helper'
module CDMDEXER
  describe DefaultSolr do
    let(:client) { Minitest::Mock.new }
    let(:connection) { Minitest::Mock.new }

    it 'establishes a connection' do
      client.expect :connect, connection, [{ url: 'http://localhost:8983/solr/blacklight-core' }]
      DefaultSolr.new('http://solr:8983/solr/some-core-here', client).connection
      client.verify
    end

    it 'persists data to solr' do
      client.expect :connect, connection, [{ url: 'http://localhost:8983/solr/blacklight-core' }]
      connection.expect :add, 'blah', [[{ id: '3sfsdf' }]]
      connection.expect :commit, nil
      DefaultSolr.new('http://solr:8983/solr/some-core-here', client).add([{ id: '3sfsdf' }])
      client.verify
    end
  end
end
