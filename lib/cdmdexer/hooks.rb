module CDMDEXER
  def self.const_missing(name)
    if name.to_s == 'Solr'
      hook(pattern: name.to_s, default: DefaultSolr)
    elsif name.to_s == 'CompletedCallback'
      hook(pattern: name.to_s, default: DefaultCompletedCallback)
    elsif name.to_s == 'OaiNotification'
      hook(pattern: name.to_s, default: DefaultOaiNotification)
    elsif name.to_s == 'LoaderNotification'
      hook(pattern: name.to_s, default: DefaultLoaderNotification)
    elsif name.to_s == 'CdmNotification'
      hook(pattern: name.to_s, default: DefaultCdmNotification)
    elsif name.to_s == 'CdmError'
      hook(pattern: name.to_s, default: DefaultCdmError)
    end
  end

  def self.hook(pattern: '', default: false)
    if find_hook(pattern, default)
      Object.const_get("CDMDEXER::#{find_hook(pattern, default)}")
    else
      default
    end
  end

  def self.find_hook(pattern, default)
    CDMDEXER.constants.find do |konst|
      if Object.const_get("CDMDEXER::#{konst}") != default
        /#{pattern}/ =~ konst.to_s
      end
    end
  end
end