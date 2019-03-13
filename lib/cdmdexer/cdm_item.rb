module CDMDEXER
  class CdmItem
    attr_reader :cdm_endpoint,
                :record,
                :collection,
                :id,
                :cdm_api_klass,
                :cdm_notification_klass

    def initialize(record: :MISSING_RECORD,
                   cdm_endpoint: :MISSING_ENDPOINT,
                   cdm_api_klass: CONTENTdmAPI::Item,
                   cdm_notification_klass: CDMDEXER::CdmNotification)
      @record                 = record
      @collection, @id        = record['id'].split(':')
      @cdm_endpoint           = cdm_endpoint
      @cdm_api_klass          = cdm_api_klass
      @cdm_notification_klass = cdm_notification_klass
    end

    def to_h
      # Preserve the record hash. It may contain compound data that has been
      # resubmitted here by the transformer_worker as it recurses through
      # compounds in order to extract their full metadata
      @to_h ||= record.merge(metadata)
    end

    def page
      primary_record.fetch('page', [])
                    .each_with_index.map { |page, i| to_compound(page, i) }
    end

    private

    def metadata
      if first_page_id
        # There are cases when we will not want to have to query for the
        #  metadata of the first item of a compound. So, include the metadata of
        # the first page in its parent record metadata.
        #
        # Use-case: you want to grab a thumbnail for the compound record. In
        # this case, you'll need the format field of the first record in order
        # to determine which thumbnail generation mechanism to use (e.g. CDM
        # thumb vs getting a thumbnail for a video from Kaltura)
        primary_record.merge('first_page' => request(first_page_id))
      else
        primary_record
      end.merge(
        'page' => page,
        # When an item has pages, these pages are resubmitted to CdmItem
        # as records in order to get their full metadata. But we want to
        # remember that they are actually secondary / child pages
        'record_type' => record.fetch('record_type', 'primary')
      )
    end

    def first_page_id
      (page.first || {}).fetch('id', '').split(':').last
    end

    def to_compound(page, i)
      # raise "#{collection}:#{page['pageptr']}".inspect
      page.merge(
        # Child id is a combo of the page id and parent collection
        'id' => "#{collection}:#{page['pageptr']}",
        'parent_id' => record['id'],
        'record_type' => 'secondary',
        'child_index' => i
      )
    end

    def primary_record
      @primary_record ||= request(id)
    end

    # CDM's id format is collection/id. We use collection:id
    def to_solr_id(record)
      record.merge('id' => record['id'].split('/').join(':'))
    end

    def request(id)
      cdm_notification_klass.call!(collection, id, cdm_endpoint)
      to_solr_id(cdm_api_klass.new(base_url: cdm_endpoint,
                        collection: collection,
                        with_compound: false,
                        id: id).metadata)
    end
  end
end