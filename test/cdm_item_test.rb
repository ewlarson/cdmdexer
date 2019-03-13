require 'test_helper'

module CDMDEXER
  describe CdmItemTest do
    it 'produces an item with compounds' do
      endpoint = 'http://example.com'
      cdm_api_klass = Minitest::Mock.new
      cdm_api_obj = Minitest::Mock.new
      cdm_api_klass.expect :new, cdm_api_obj, [
        {
          base_url: endpoint,
          collection: 'fooCol',
          with_compound: false,
          id: '123'
        }
      ]
      cdm_api_klass.expect :new, cdm_api_obj, [
        {
          base_url: endpoint,
          collection: 'fooCol',
          with_compound: false,
          id: '0'
        }
      ]
      compound_record = { 'id' => 'fooCol:123', 'page' => [{ 'pageptr' => 0, 'blah' => 'blah' }, { 'pageptr' => 1, 'bar' => 'bar' }]}
      first_page_cmd_response = { 'id' => 'fooCol/0', 'blah' => 'blah'}
      cdm_api_obj.expect :metadata, compound_record, []
      cdm_api_obj.expect :metadata, first_page_cmd_response, []
      cdm_item = CdmItem.new(record: compound_record,
                             cdm_endpoint: endpoint,
                             cdm_api_klass: cdm_api_klass)
      cdm_item.to_h.must_equal(
        {
         "id"=>"fooCol:123",
         "page"=>[{"pageptr"=>0, "blah"=>"blah", "id"=>"fooCol:0", "parent_id"=>"fooCol:123", "record_type"=>"secondary", "child_index"=>0}, {"pageptr"=>1, "bar"=>"bar", "id"=>"fooCol:1", "parent_id"=>"fooCol:123", "record_type"=>"secondary", "child_index"=>1}],
         "first_page"=>{"id"=>"fooCol:0", "blah"=>"blah"},
         "record_type"=>"primary"
        }
      )
      cdm_api_klass.verify
      cdm_api_obj.verify
    end

    describe 'when given a compound page (from a previous request' do
      it 'retains the item classification as a secondary record type' do
        record = { 'id' => 'fooCol:123', 'record_type' => 'secondary', 'foo' => 'bar' }
        endpoint = 'http://example.com'
        cdm_api_klass = Minitest::Mock.new
        cdm_api_obj = Minitest::Mock.new
        cdm_api_klass.expect :new, cdm_api_obj, [
          {
            base_url: endpoint,
            collection: 'fooCol',
            with_compound: false,
            id: '123'
          }
        ]
        cdm_api_obj.expect :metadata, {'page' => [], 'id' => 'fooCol/123'}, []
        cdm_item = CdmItem.new(record: record,
                               cdm_endpoint: endpoint,
                               cdm_api_klass: cdm_api_klass)
        cdm_item.to_h.must_equal({"id"=>"fooCol:123", "record_type"=>"secondary", "foo"=>"bar", "page"=>[]})
        cdm_api_klass.verify
        cdm_api_obj.verify
      end
    end
  end
end