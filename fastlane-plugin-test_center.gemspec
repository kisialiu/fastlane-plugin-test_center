
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/test_center/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-test_center'
  spec.version       = Fastlane::TestCenter::VERSION
  spec.author        = 'Lyndsey Ferguson'
  spec.email         = 'ldf.public+github@outlook.com'

  spec.summary       = 'Makes testing your iOS app easier'
  spec.homepage      = "https://github.com/lyndsey-ferguson/fastlane-plugin-test_center"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.description = <<-SUMMARY
    This fastlane plugin includes the following actions:
    1) multi_scan: uses scan to run Xcode tests a given number of times: only re-testing failing tests.
    2) suppress_tests_from_junit: uses a junit xml report file to suppress either passing or failing tests in an Xcode Scheme.
    3) suppress_tests: suppresses specific tests in a specific or all Xcode Schemes in a given project.
    4) suppressed_tests: retrieves a list of tests that are suppressed in a specific or all Xcode Schemes in a project.
    5) tests_from_junit: retrieves the failing and passing tests as reported in a junit xml file.
    6) collate_junit_reports: collects and correctly organizes junit reports from multiple test passes.
  SUMMARY

  spec.add_dependency 'xcodeproj'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'fastlane', '>= 2.56.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
