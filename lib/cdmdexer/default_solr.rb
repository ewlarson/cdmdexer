require 'rsolr'

module CDMDEXER
  # Commnicate with Solr: add / delete stuff
  class DefaultSolr
    attr_reader :url, :client
    def initialize(url='http://localhost:8983/solr/blacklight-core', client= RSolr)
      @url    = url
      @client = client
    end

    def ids(start: 0)
      connection.get('select',
        :params => { :q => '*:*',
          :defType => 'edismax',
          :fl => '',
          :rows => 10,
          :start => start
        }
      )
    end

    def connection
      @connection ||= client.connect url
    end

    def add(records)
      connection.add records
    end

    def delete(ids)
      connection.delete_by_id ids
    end
  end
end
