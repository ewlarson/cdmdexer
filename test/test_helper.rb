# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'dotenv/load'
require 'cdmdexer'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/spec'
require 'sidekiq/testing'
# Hash.from_xml
# Rails cache
require 'rails'
require 'byebug'

# Rails turns off backtraces, turn them back on
ENV['BACKTRACE'] = 'YES '

# Config: set Settings object
require 'config'

# Avoid testing solr itself
module CDMDEXER
  class TestConnection
    def get(_query, _params)
      {
        'response' => {
          'docs' => [
            { 'id' => 'irrc:1600' },
            { 'id' => 'irrc:1601' },
            { 'id' => 'irrc:1601' },
            { 'id' => 'irrc:1568' },
            { 'id' => 'irrc:1569' },
            { 'id' => 'irrc:1747' },
            { 'id' => 'otter:297' },
            { 'id' => 'nemhc:5897' },
            { 'id' => 'pch:612' },
            { 'id' => 'bad:ID' }
          ],
          'numFound' => 10
        }
      }
    end

    def add(records); end

    def commit; end

    def delete_by_id(ids); end
  end

  class TestClient
    def self.connect(_url)
      TestConnection.new
    end
  end

  class TestSolr < DefaultSolr
    def initialize(url: 'http://localhost:8983', client: TestClient)
      super(url: url, client: client)
    end
  end

  # An example callback
  class Callback
    def self.call!(_solr_client)
      'blerg this is a test callback'
    end
  end
end

class Settings
  def self.field_mappings
    Config.load_files(File.join(File.dirname(__FILE__),
                                '../lib/generators/cdmdexer/templates/settings.yml')).field_mappings
  end
end
