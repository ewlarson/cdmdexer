module CDMDEXER
  # "Record Transformation Error: #{message}"
  class RecordTransformer
    attr_reader :record, :field_mappings, :field_transformer, :error_klass
    def initialize(record: {},
                   field_mappings: [],
                   field_transformer: FieldTransformer,
                   error_klass: TransformationErrorMessage)
      @record            = record
      @field_mappings    = field_mappings
      @field_transformer = field_transformer
      @error_klass = error_klass
    end

    def transform!
      field_mappings.inject({}) do |dest_record, field_mapping|
        dest_record.merge(transform_field(record, field_mapping))
      end
    rescue StandardError => error
      error_klass.new(message: message(error)).notify
    end

    private

    def message(error)
      "Record Transformation Error (Record #{record['id']}): #{error}"
    end

    def transform_field(record, field_mapping)
      field_transformer.new(field_mapping: field_mapping,
                            record: record).reduce
    end
  end
end
