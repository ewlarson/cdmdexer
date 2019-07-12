module CDMDEXER
  # An example callback
  class DefaultCdmError
    def self.call!(error)
      puts "CDMDEXER Error: #{error}"
    end
  end
end