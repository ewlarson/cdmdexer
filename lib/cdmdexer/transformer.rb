require 'json'
require 'titleize'
require 'active_support/core_ext/integer/time'

module CDMDEXER
  class Transformer
    attr_reader :cdm_records,
                :oai_endpoint,
                :field_mappings,
                :record_transformer,
                :cache_klass,
                :oai_request_klass

    def initialize(cdm_records: [],
                   oai_endpoint: :MISSING_OAI_ENDPOINT,
                   field_mappings: false,
                   record_transformer: RecordTransformer,
                   cache_klass: ::Rails,
                   oai_request_klass: OaiRequest)
      @cdm_records        = cdm_records
      @oai_endpoint       = oai_endpoint
      @field_mappings     = default_field_mappings
      @record_transformer = record_transformer
      @cache_klass        = cache_klass
      @oai_request_klass  = oai_request_klass
    end

    def records
      cdm_records.map { |record| to_solr(record) }.compact
    end

    private

    def sets
      @oai_request ||=
        cache_klass.cache.fetch("cdmdexer_sets", expires_in: 10.minutes) do
          oai_request_klass.new(endpoint_url: oai_endpoint).set_lookup
        end
    end

    def mappings
      field_mappings.map { |config| FieldMapping.new(config: config) }
    end

    def to_solr(record)
      # Remove empty records (move this behavior to the CONTENTdm API gem) and
      # bail early on the transformation process
      if {'id' => record['id']} == record
        return nil
      else
        record_transformer.new(record: record.merge('oai_sets' => sets),
                               field_mappings: mappings).transform!
      end
    end

    def default_field_mappings
      Settings.field_mappings
    end
  end
end
