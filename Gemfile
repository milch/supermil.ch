source 'https://rubygems.org'

gem 'fastlane'
gem 'aws-sdk', '< 2'
gem 'mime-types', '~> 3.0'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval(File.read(plugins_path), binding) if File.exist?(plugins_path)
