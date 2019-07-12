require 'test_helper'

module CDMDEXER

  describe FieldTransformer do
    let(:formatter) { Minitest::Mock.new }
    let(:formatter_object) { Minitest::Mock.new }
    let(:field_mapping) { Minitest::Mock.new }
    let(:record) { { 'title' => '  The Stars My Destination  ' } }

    it 'calls the field formatter for each mapping' do
      formatter.expect :new, formatter_object, [{:value=>'  The Stars My Destination  ', :formatters=>[CDMDEXER::DefaultFormatter]}]
      formatter_object.expect :format!, 'The Stars My Destination'
      field_mapping.expect :origin_path, 'title', []
      field_mapping.expect :dest_path, 'title_ssi', []
      field_mapping.expect :formatters, [DefaultFormatter], []
      transformer = FieldTransformer.new(field_mapping: field_mapping,
                                         record: record,
                                         formatter_klass: formatter)
      transformer.reduce.must_equal({"title_ssi"=>"The Stars My Destination"})
      formatter.verify
      field_mapping.verify
    end

    describe 'when a field transformation results in an error' do
      it 'returns the record id along with the error message' do
        class BadFormatterWut
          def self.format(value)
            raise 'wuuuuut'
          end
        end

        config = { dest_path: 'title', origin_path: 'title', formatters: [BadFormatterWut] }
        field_mapping = FieldMapping.new(config: config)
        record = {'title' => 'foo' }
        transformer = FieldTransformer.new(field_mapping: field_mapping, record: record)
        err = ->{ transformer.reduce }.must_raise RuntimeError
        err.message.must_equal "Mapping: {:dest_path=>\"title\", :origin_path=>\"title\", :formatters=>[CDMDEXER::BadFormatterWut]} Error:wuuuuut"
      end
    end
  end
end