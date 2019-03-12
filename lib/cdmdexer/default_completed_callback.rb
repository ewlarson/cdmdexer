module CDMDEXER
  # An example callback
  class DefaultCompletedCallback
    def self.call!(solr_client)
      puts "A callback task"
    end
  end
end