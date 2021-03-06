
def create_configuraton(values)
  FastlaneCore::Configuration.create(
    Fastlane::Actions::ScanAction.available_options,
    values.merge(output_directory: 'output_directory')
  ).values
end

describe Fastlane::Actions::MultiScanAction do
  before(:each) do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(%r{.*path/to/fake_junit_report.xml}).and_return(true)

    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(%r{.*path/to/fake_junit_report.xml}).and_yield(File.open('./spec/fixtures/junit.xml'))
    allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: [], passing: [] })

    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with(%r{.*/*.junit}).and_return([File.absolute_path('./spec/fixtures/junit.xml')])
    allow(Dir).to receive(:glob).with(%r{.*/*.xml}).and_return([File.absolute_path('./spec/fixtures/junit.xml')])
    allow(Fastlane::Actions::CollateJunitReportsAction).to receive(:run)
    allow(FileUtils).to receive(:rm_f).with([%r{.*/*.xml}])
  end

  describe 'config methods' do
    [
      {
        config: {
          output_types: 'junit',
          output_files: 'report.xml',
          output_directory: 'output_directory'
        },
        desired_has_junit_result: true,
        desired_config_with_junit_result: true,
        desired_report_filepath: 'report.xml'
      },
      {
        config: {
          output_types: 'html,junit',
          output_files: 'report.html,report.xml',
          output_directory: 'output_directory'
        },
        desired_has_junit_result: true,
        desired_config_with_junit_result: true,
        desired_report_filepath: 'report.xml'
      },
      {
        config: {
          output_types: 'junit',
          custom_report_file_name: 'my_test_report.xml',
          output_directory: 'output_directory'
        },
        desired_has_junit_result: true,
        desired_config_with_junit_result: true,
        desired_report_filepath: 'my_test_report.xml'
      },
      {
        config: {
          output_types: 'junit',
          output_directory: 'output_directory'
        },
        desired_has_junit_result: false, # because a raw config must also have the report filename
        desired_config_with_junit_result: true,
        desired_report_filepath: 'report.xml'
      },
      {
        config: {
          output_directory: 'output_directory'
        },
        desired_has_junit_result: false,
        desired_config_with_junit_result: true,
        desired_report_filepath: 'report.xml'
      },
      {
        config: {
          custom_report_file_name: 'just_a_custom_report_filename.xml',
          output_directory: 'output_directory'
        },
        desired_has_junit_result: true, # true because the default value for :output_types is 'html,junit'
        desired_config_with_junit_result: true,
        desired_report_filepath: 'just_a_custom_report_filename.xml'
      },
      {
        config: {
          output_types: 'html',
          output_files: 'report.html',
          output_directory: 'output_directory'
        },
        desired_has_junit_result: false,
        desired_config_with_junit_result: true,
        desired_report_filepath: 'report.xml'
      }
    ].each do |test_data|
      it "config_has_junit_report is  #{test_data[:desired_has_junit_result]} with #{test_data[:config]}" do
        config = create_configuraton(test_data[:config])
        has_junit = Fastlane::Actions::MultiScanAction.config_has_junit_report(config)
        expect(has_junit).to be(test_data[:desired_has_junit_result])
      end

      it "config_with_junit_report with #{test_data[:config]} is #{test_data[:desired_has_junit_result]}" do
        config = Fastlane::Actions::MultiScanAction.config_with_junit_report(test_data[:config])
        expect(Fastlane::Actions::MultiScanAction.config_has_junit_report(config)).to eq(test_data[:desired_config_with_junit_result])
      end

      it "junit_report_filepath for #{test_data[:config]} is #{test_data[:desired_report_filepath]}" do
        config = Fastlane::Actions::MultiScanAction.config_with_junit_report(test_data[:config])
        junit_report_filepath = Fastlane::Actions::MultiScanAction.junit_report_filepath(config)
        expect(File.basename(junit_report_filepath)).to eq(test_data[:desired_report_filepath])
      end

      it "increment_report_filenames for #{test_data[:config]} is #{File.basename(test_data[:desired_report_filepath], '.*')}-2.xml" do
        config = Fastlane::Actions::MultiScanAction.config_with_junit_report(test_data[:config])
        Fastlane::Actions::MultiScanAction.increment_report_filenames(config)
        junit_report_filepath = Fastlane::Actions::MultiScanAction.junit_report_filepath(config)
        expect(File.basename(junit_report_filepath)).to eq("#{File.basename(test_data[:desired_report_filepath], '.*')}-2.xml")
      end

      it "increment_report_filenames x 3 for #{test_data[:config]} is #{File.basename(test_data[:desired_report_filepath], '.*')}-4.xml" do
        config = Fastlane::Actions::MultiScanAction.config_with_junit_report(test_data[:config])
        Fastlane::Actions::MultiScanAction.increment_report_filenames(config)
        junit_report_filepath = Fastlane::Actions::MultiScanAction.junit_report_filepath(config)
        expect(File.basename(junit_report_filepath)).to eq("#{File.basename(test_data[:desired_report_filepath], '.*')}-3.xml")
        Fastlane::Actions::MultiScanAction.increment_report_filenames(config)
        junit_report_filepath = Fastlane::Actions::MultiScanAction.junit_report_filepath(config)
        expect(File.basename(junit_report_filepath)).to eq("#{File.basename(test_data[:desired_report_filepath], '.*')}-4.xml")
      end
    end
  end

  describe 'it lives' do
    it 'it calls scan' do
      non_existent_project = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          test_without_building: true,
          derived_data_path: 'path/to/derived_data'
        )
      end"

      expect(Fastlane::Actions::ScanAction).to receive(:run)
      Fastlane::FastFile.new.parse(non_existent_project).runner.execute(:test)
    end

    it 'it calls scan twice for a fragile test' do
      non_existent_project = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          try_count: 2,
          test_without_building: true,
          derived_data_path: 'path/to/derived_data'
        )
      end"
      scan_count = 0
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:available_options).and_return([])
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'] })
      allow(Fastlane::Actions::ScanAction).to receive(:run) do |config|
        scan_count += 1
        fail FastlaneCore::Interface::FastlaneTestFailure, 'Fake test failure' if scan_count == 1
        0
      end
      Fastlane::FastFile.new.parse(non_existent_project).runner.execute(:test)
      expect(scan_count).to eq(2)
    end

    it 'it calls scan twice for a fragile test but testing only failing tests' do
      non_existent_project = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          try_count: 2,
          custom_report_file_name: 'fake_junit_report.xml',
          output_directory: 'path/to',
          test_without_building: true,
          derived_data_path: 'path/to/derived_data'
        )
      end"
      scan_count = 0

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(%r{.*path/to/fake_junit_report.xml}).and_return(true)
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'] })

      allow(Fastlane::Actions::ScanAction).to receive(:run) do |config|
        scan_count += 1
        fail FastlaneCore::Interface::FastlaneTestFailure, 'Fake test failure' if scan_count == 1
        expect(config[:only_testing]).to eq(['BagOfTests/CoinTossingUITests/testResultIsTails'])
        0
      end
      Fastlane::FastFile.new.parse(non_existent_project).runner.execute(:test)
      expect(scan_count).to eq(2)
    end

    it 'a second scan does not build again' do
      non_existent_project = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          try_count: 2,
          custom_report_file_name: 'fake_junit_report.xml',
          output_directory: 'path/to'
        )
      end"
      scan_count = 0

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(%r{.*path/to/fake_junit_report.xml}).and_return(true)
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: ['BagOfTests/CoinTossingUITests/testResultIsTails', 'Bag Of Tests/CoinTossingUITests/testResultIsMonkeys'] })

      allow(Fastlane::Actions::ScanAction).to receive(:run) do |config|
        scan_count += 1
        case scan_count
        when 1
          expect(config[:test_without_building]).to be_falsey
          expect(config[:build_for_testing]).to be(true)
        when 2
          expect(config[:test_without_building]).to be(true)
          expect(config[:build_for_testing]).to be_falsey
          raise FastlaneCore::Interface::FastlaneTestFailure, 'Fake test failure'
        when 3
          expect(config[:custom_report_file_name]).to eq('fake_junit_report-2.xml')
          expect(config[:test_without_building]).to be(true)
          expect(config[:build_for_testing]).to be_falsey
          expect(config[:only_testing]).to eq(['BagOfTests/CoinTossingUITests/testResultIsTails', 'Bag\\ Of\\ Tests/CoinTossingUITests/testResultIsMonkeys'])
        end
        0
      end
      Fastlane::FastFile.new.parse(non_existent_project).runner.execute(:test)
      expect(scan_count).to eq(3)
    end

    it 'it merges junit reports' do
      non_existent_project = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          try_count: 2,
          test_without_building: true,
          derived_data_path: 'path/to/derived_data'
        )
      end"
      scan_count = 0
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:available_options).and_return([])
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'] })
      allow(Dir).to receive(:glob).with(%r{.*/*.junit}).and_return([File.absolute_path('./spec/fixtures/junit.xml'), File.absolute_path('./spec/fixtures/junit.xml')])
      allow(FileUtils).to receive(:rm_f).with([%r{.*/*.xml}, %r{.*/*.xml}])
      allow(Fastlane::Actions::ScanAction).to receive(:run) do |config|
        scan_count += 1
        raise FastlaneCore::Interface::FastlaneTestFailure, 'Fake test failure' if scan_count == 1
        0
      end
      expect(Fastlane::Actions::CollateJunitReportsAction).to receive(:run)
      Fastlane::FastFile.new.parse(non_existent_project).runner.execute(:test)
    end

    it 'it sends scan correct incremented report names for html, junit' do
      non_existent_project_junit = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          try_count: 2,
          test_without_building: true,
          derived_data_path: 'path/to/derived_data'
        )
      end"
      scan_count = 0
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:available_options).and_return([])
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'] })
      allow(Fastlane::Actions::ScanAction).to receive(:run) do |config|
        suffix = scan_count == 0 ? '' : "-#{scan_count + 1}"
        expect(config._values[:output_files]).to eq("report#{suffix}.html,report#{suffix}.junit")
        scan_count += 1
        raise FastlaneCore::Interface::FastlaneTestFailure, 'Fake test failure' if scan_count == 1
        0
      end
      Fastlane::FastFile.new.parse(non_existent_project_junit).runner.execute(:test)
    end

    it 'it sends scan correct incremented report names for html, xml' do
      non_existent_project_xml = "lane :test do
        multi_scan(
          project: File.absolute_path('../AtomicBoy/AtomicBoy.xcodeproj'),
          scheme: 'AtomicBoy',
          try_count: 3,
          test_without_building: true,
          derived_data_path: 'path/to/derived_data',
          output_files: 'report.html,report.xml'
        )
      end"
      scan_count = 0
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:available_options).and_return([])
      allow(Fastlane::Actions::TestsFromJunitAction).to receive(:run).and_return({ failed: ['BagOfTests/CoinTossingUITests/testResultIsTails'] })
      allow(Fastlane::Actions::ScanAction).to receive(:run) do |config|
        suffix = scan_count == 0 ? '' : "-#{scan_count + 1}"
        expect(config._values[:output_files]).to eq("report#{suffix}.html,report#{suffix}.xml")
        scan_count += 1
        raise FastlaneCore::Interface::FastlaneTestFailure, 'Fake test failure' if scan_count < 4
        0
      end
      Fastlane::FastFile.new.parse(non_existent_project_xml).runner.execute(:test)
    end
  end
end
