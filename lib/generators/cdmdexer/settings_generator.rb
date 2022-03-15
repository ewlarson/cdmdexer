# frozen_string_literal: true
require 'rails/generators'

module Cdmdexer
  class SettingsGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    desc <<-EOF
      This generator makes the following changes to your application:
       1. Installs settings.yml into your application's config directory
    EOF

    def add_initializer
      copy_file 'rails_config.rb', 'config/initializers/rails_config.rb'
    end

    def install_settings
      copy_file 'cdmdexer.yml', 'config/initializers/cdmdexer.yml'
    end
  end
end
