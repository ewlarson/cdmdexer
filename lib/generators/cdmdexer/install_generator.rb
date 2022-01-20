# frozen_string_literal: true
require 'rails/generators'

module CDMDEXER
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc 'Install CDMDEXER'

    def rails_config
      copy_file 'settings.yml', 'config/settings.yml'
    end

    def bundle_install
      Bundler.with_clean_env do
        run 'bundle install'
      end
    end
  end
end
