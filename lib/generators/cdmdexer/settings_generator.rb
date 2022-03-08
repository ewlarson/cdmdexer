# frozen_string_literal: true
require 'rails/generators'

module Cdmdexer
  class SettingsGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    desc <<-EOF
      This generator makes the following changes to your application:
       1. Installs settings.yml into your application's config directory
    EOF

    def install_settings
      copy_file 'settings.yml', 'config/settings.yml'
    end
  end
end
