# frozen_string_literal: true
require 'rails/generators'

module CDMDEXER
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc 'Install CDMDEXER'

    def add_rails_config_settings
      generate 'cdmdexer:settings' unless options[:'skip-solr']
    end
  end
end
