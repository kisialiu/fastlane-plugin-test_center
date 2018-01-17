source 'https://rubygems.org'

gemspec
gem 'fastlane-plugin-merge_junit_report', :path => '../merge_junit_report'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
