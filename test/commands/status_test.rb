# frozen_string_literal: true
require "test_helper"
require "test_helpers/command_test_helpers"

describe Licensed::Commands::Status do
  include CommandTestHelpers

  let(:cache_path) { Dir.mktmpdir }
  let(:reporter) { TestReporter.new }
  let(:apps) { [] }
  let(:source_config) { {} }
  let(:command_config) { { "apps" => apps, "cache_path" => cache_path, "sources" => { "test" => true }, "test" => source_config } }
  let(:config) { Licensed::Configuration.new(command_config) }
  let(:fixtures) { File.expand_path("../../fixtures", __FILE__) }
  let(:command) { Licensed::Commands::Status.new(config: config) }

  def dependency_errors(app, source, dependency_name = "dependency")
    app_report = reporter.report.reports.find { |r| r.name == app["name"] }
    assert app_report

    source_report = app_report.reports.find { |r| r.target == source }
    assert source_report

    dependency_report = source_report.reports.find { |r| r.name.include?(dependency_name) }
    dependency_report&.errors || []
  end

  def generate_metadata_files
    generator_config = Marshal.load(Marshal.dump(config))
    generator = Licensed::Commands::Cache.new(config: generator_config)
    generator.run(force: true, reporter: TestReporter.new)
  end

  describe "with cached metadata data source" do
    before do
      generate_metadata_files
    end

    after do
      config.apps.each do |app|
        FileUtils.rm_rf app.cache_path
      end
    end

    it "warns if license is not allowed" do
      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert_includes dependency_errors(app, source), "license needs review: mit"
        end
      end
    end

    it "warns if license text changed and needs re-review" do
      config.apps.each do |app|
        path = app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
        record = Licensed::DependencyRecord.read(path)
        record["review_changed_license"] = true
        record.save(path)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert_includes \
            dependency_errors(app, source),
            "license text has changed and needs re-review. if the new text is ok, remove the `review_changed_license` flag from the cached record"
        end
      end
    end

    it "does not warn if license is allowed" do
      config.apps.each do |app|
        app.allow "mit"
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          refute_includes dependency_errors(app, source), "license needs review: mit"
        end
      end
    end

    it "does not warn if dependency is ignored" do
      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).any?
          app.ignore({ "type" => source.class.type, "name" => "dependency" })
        end
      end

      run_command

      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).empty?
        end
      end
    end

    it "does not warn if dependency is reviewed" do
      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).any?
          app.ignore({ "type" => source.class.type, "name" => "dependency" })
        end
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).empty?
        end
      end
    end

    it "warns if license is empty" do
      config.apps.each do |app|
        filename = app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
        record = Licensed::DependencyRecord.new
        record.save(filename)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert_includes dependency_errors(app, source), "missing license text"
        end
      end
    end

    it "warns if record is empty with notices" do
      config.apps.each do |app|
        filename = app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
        record = Licensed::DependencyRecord.new(notices: ["notice"])
        record.save(filename)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert_includes dependency_errors(app, source), "missing license text"
        end
      end
    end

    it "does not warn if license is not empty" do
      config.apps.each do |app|
        filename = app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
        record = Licensed::DependencyRecord.new(licenses: ["license"])
        record.save(filename)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          refute_includes dependency_errors(app, source), "missing license text"
        end
      end
    end

    it "warns if versions do not match" do
      config.apps.each do |app|
        filename = app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
        record = Licensed::DependencyRecord.read(filename)
        record["version"] = "9001"
        record.save(filename)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert_includes dependency_errors(app, source), "dependency record out of date"
        end
      end
    end

    it "warns if cached license data missing" do
      config.apps.each do |app|
        FileUtils.rm app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert_includes dependency_errors(app, source), "cached dependency record not found"
        end
      end
    end

    it "does not warn if cached license data missing for ignored gem" do
      config.apps.each do |app|
        FileUtils.rm app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
        app.ignore({ "type" => "test", "name" => "dependency" })
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          refute_includes dependency_errors(app, source), "dependency record not found"
        end
      end
    end

    it "reports a link to the documentation on any failures" do
      # this is the same error case as "warns if license is not allowed"
      run_command

      command_errors = reporter.report.errors
      refute_empty command_errors
      assert command_errors.any? { |e| e =~ /Licensed found errors during source enumeration.  Please see/ }
    end

    it "does not include ignored dependencies in dependency counts" do
      run_command
      count = reporter.report.all_reports.size

      config.apps.each do |app|
        app.ignore({ "type" => "test", "name" => "dependency" })
      end

      run_command
      ignored_count = reporter.report.all_reports.size

      assert_equal count - config.apps.size, ignored_count
    end

    it "changes the current directory to app.source_path while running" do
      config.apps.each do |app|
        app["source_path"] = fixtures
      end

      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert dependency_report
      assert_equal fixtures, dependency_report.target.path
    end

    it "reports whether a dependency is allowed" do
      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      refute dependency_report["allowed"]

      config.apps.each do |app|
        app.sources.each do |source|
          app.review({ "type" => source.class.type, "name" => "dependency" })
        end
      end

      reporter.report.all_reports.clear

      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert dependency_report["allowed"]
    end

    it "reports a cached record's recorded license" do
      run_command
      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert_equal "mit", dependency_report["license"]
    end

    describe "with multiple apps" do
      let(:apps) do
        [
          {
            "name" => "app1",
            "cache_path" => "vendor/licenses/app1",
            "source_path" => Dir.pwd
          },
          {
            "name" => "app2",
            "cache_path" => "vendor/licenses/app2",
            "source_path" => Dir.pwd
          }
        ]
      end

      it "verifies dependencies for all apps" do
        run_command
        apps.each do |app|
          assert reporter.report.reports.find { |report| report.name == app["name"] }
        end
      end
    end

    describe "with explicit dependency file path" do
      let(:source_config) { { name: "dependency/path" } }

      it "verifies content at explicit path" do
        config.apps.each do |app|
          filename = app.cache_path.join("test/dependency/path.#{Licensed::DependencyRecord::EXTENSION}")
          record = Licensed::DependencyRecord.new
          record.save(filename)
        end

        run_command
        config.apps.each do |app|
          app.sources.each do |source|
            assert_includes dependency_errors(app, source, "dependency/path"), "missing license text"
          end
        end
      end
    end

    describe "with multiple cached license notices" do
      let(:bsd_3) { Licensed::DependencyRecord::License.new(Licensee::License.find("bsd-3-clause").to_s) }
      let(:mit) { Licensed::DependencyRecord::License.new(Licensee::License.find("mit").to_s) }
      let(:agpl_3) { Licensed::DependencyRecord::License.new(Licensee::License.find("agpl-3.0").to_s) }
      let(:readme_mit) { Licensed::DependencyRecord::License.new("## License:\n\nMIT") }

      before do
        config.apps.each do |app|
          app.allow("mit")
          app.allow("bsd-3-clause")
        end
      end

      def update_records(classification, *licenses)
        config.apps.each do |app|
          path = app.cache_path.join("test/dependency.#{Licensed::DependencyRecord::EXTENSION}")
          record = Licensed::DependencyRecord.read(path)
          record.licenses.clear
          record.licenses.push(*licenses)
          record["license"] = classification
          record.save(path)
        end
      end

      it "does not warn if the top level license field is allowed" do
        # licenses contains an unapproved license notice (agpl-3.0), but should not be checked
        # because the top level license field is allowed
        update_records("mit", mit, agpl_3)

        run_command
        config.apps.each do |app|
          app.sources.each do |source|
            assert dependency_errors(app, source).empty?
          end
        end
      end

      it "warns if the top level license field is not allowed and not 'other'" do
        # both record license texts are approved, but licensed should only check
        # them when the record's top level license field is set to other
        update_records("agpl-3.0", mit, bsd_3)

        run_command
        config.apps.each do |app|
          app.sources.each do |source|
            assert_includes dependency_errors(app, source), "license needs review: agpl-3.0"
          end
        end
      end

      it "warns if any of the license notices is not allowed" do
        # licenses contains an unapproved license notice (agpl-3.0),
        # and will be checked because the top level license field is set to other
        update_records("other", mit, agpl_3)

        run_command
        config.apps.each do |app|
          app.sources.each do |source|
            assert_includes dependency_errors(app, source), "license needs review: other"
          end
        end
      end

      it "does not warn if all of the license notices are allowed" do
        # licenses contains only approved values, which pass status checks
        # when the top level license field is set to other
        update_records("other", mit, bsd_3)

        run_command
        config.apps.each do |app|
          app.sources.each do |source|
            assert dependency_errors(app, source).empty?
          end
        end
      end

      it "parses readme contents as well as license text" do
        # licenses includes content that will be matched as part of a README file,
        # but not as part of a LICENSE file
        update_records("other", readme_mit, bsd_3)

        run_command
        config.apps.each do |app|
          app.sources.each do |source|
            assert dependency_errors(app, source).empty?
          end
        end
      end
    end
  end

  describe "with configuration data source" do
    def run_command(**opts)
      opts = { data_source: "configuration" }.merge(opts)
      super(**opts)
    end

    it "does not warn if license is allowed" do
      config.apps.each do |app|
        app.allow "mit"
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          refute_includes dependency_errors(app, source), "dependency needs review"
        end
      end
    end

    it "does not warn if dependency is ignored" do
      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).any?
          app.ignore({ "type" => source.class.type, "name" => "dependency" })
        end
      end

      run_command

      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).empty?
        end
      end
    end

    it "does not warn if dependency is reviewed at a specific version" do
      run_command
      config.apps.each do |app|
        app.review({
          "type" => TestSource.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => TestSource::DEPENDENCY_VERSION
        }, at_version: true)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).empty?
        end
      end
    end

    it "warns if dependency is marked reviewed without version" do
      config.apps.each do |app|
        app.review({
          "type" => TestSource.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME
        })
      end

      run_command

      dependency_report = reporter.report.all_reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert(dependency_report.errors.any? do |e|
        e.match?("dependency needs review") &&
          e.match?("unversioned 'reviewed' match found: #{TestSource::DEFAULT_DEPENDENCY_NAME}")
      end)
    end

    it "warns if dependency is reviewed at different version" do
      config.apps.each do |app|
        app.review({
          "type" => TestSource.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => "0.0.0",
        }, at_version: true)
      end

      run_command

      dependency_report = reporter.report.all_reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert(dependency_report.errors.any? do |e|
        e.match?("dependency needs review") &&
          e.match?("possible 'reviewed' matches found at other versions: #{TestSource::DEFAULT_DEPENDENCY_NAME}@0.0.0")
      end)
    end

    it "reports a link to the documentation on any failures" do
      # this is the same error case as "warns if license is not allowed"
      run_command

      command_errors = reporter.report.errors
      refute_empty command_errors
      assert command_errors.any? { |e| e =~ /Licensed found errors during source enumeration.  Please see/ }
    end

    it "does not include ignored dependencies in dependency counts" do
      run_command
      count = reporter.report.all_reports.size

      config.apps.each do |app|
        app.ignore({ "type" => "test", "name" => "dependency" })
      end

      run_command
      ignored_count = reporter.report.all_reports.size

      assert_equal count - config.apps.size, ignored_count
    end

    it "changes the current directory to app.source_path while running" do
      config.apps.each do |app|
        app["source_path"] = fixtures
      end

      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert dependency_report
      assert_equal fixtures, dependency_report.target.path
    end

    it "reports whether a dependency is allowed" do
      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      refute dependency_report["allowed"]

      config.apps.each do |app|
        app.review({
          "type" => TestSource.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => TestSource::DEPENDENCY_VERSION
        }, at_version: true)
      end

      reporter.report.all_reports.clear

      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert dependency_report["allowed"]
    end

    it "reports a cached record's recorded license" do
      run_command
      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert_equal "mit", dependency_report["license"]
    end

    describe "with multiple apps" do
      let(:apps) do
        [
          {
            "name" => "app1",
            "cache_path" => "vendor/licenses/app1",
            "source_path" => Dir.pwd
          },
          {
            "name" => "app2",
            "cache_path" => "vendor/licenses/app2",
            "source_path" => Dir.pwd
          }
        ]
      end

      it "verifies dependencies for all apps" do
        run_command
        apps.each do |app|
          assert reporter.report.reports.find { |report| report.name == app["name"] }
        end
      end
    end
  end

  describe "with cached metadata source that requires versions" do
    let(:config) { Licensed::Configuration.new("apps" => apps, "cache_path" => cache_path, "sources" => { "test_dependency_version_names" => true }, "test_dependency_version_names" => source_config) }

    before do
      generator_config = Marshal.load(Marshal.dump(config))
      generator = Licensed::Commands::Cache.new(config: generator_config)
      generator.run(force: true, reporter: TestReporter.new)
    end

    after do
      config.apps.each do |app|
        FileUtils.rm_rf app.cache_path
      end
    end

    it "does not warn if license is allowed" do
      config.apps.each do |app|
        app.allow "mit"
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          refute_includes dependency_errors(app, source), "needs review"
        end
      end
    end

    it "does not warn if dependency is ignored" do
      run_command
      config.apps.each do |app|
        app.ignore({
          "type" => TestSourceWithDependencyVersionNames.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => TestSource::DEPENDENCY_VERSION
        }, at_version: true)
      end

      run_command

      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).empty?
        end
      end
    end

    it "does not warn if dependency is reviewed at a specific version" do
      run_command
      config.apps.each do |app|
        app.review({
          "type" => TestSourceWithDependencyVersionNames.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => TestSource::DEPENDENCY_VERSION
        }, at_version: true)
      end

      run_command
      config.apps.each do |app|
        app.sources.each do |source|
          assert dependency_errors(app, source).empty?
        end
      end
    end

    it "warns if dependency is marked reviewed without version" do
      config.apps.each do |app|
        app.review({
          "type" => TestSourceWithDependencyVersionNames.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME
        })
      end

      run_command

      dependency_report = reporter.report.all_reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert(dependency_report.errors.any? do |e|
        e.match?("license needs review: mit")
      end)
    end

    it "warns if dependency is reviewed at different version" do
      config.apps.each do |app|
        app.review({
          "type" => TestSourceWithDependencyVersionNames.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => "0.0.0",
        }, at_version: true)
      end

      run_command

      dependency_report = reporter.report.all_reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert(dependency_report.errors.any? do |e|
        e.match?("license needs review: mit")
      end)
    end

    it "reports a link to the documentation on any failures" do
      # this is the same error case as "warns if license is not allowed"
      run_command

      command_errors = reporter.report.errors
      refute_empty command_errors
      assert command_errors.any? { |e| e =~ /Licensed found errors during source enumeration.  Please see/ }
    end

    it "does not include ignored dependencies in dependency counts" do
      run_command
      count = reporter.report.all_reports.size

      config.apps.each do |app|
        app.ignore({
          "type" => TestSourceWithDependencyVersionNames.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => TestSource::DEPENDENCY_VERSION,
        }, at_version: true)
      end

      run_command
      ignored_count = reporter.report.all_reports.size

      assert_equal count - config.apps.size, ignored_count
    end

    it "changes the current directory to app.source_path while running" do
      config.apps.each do |app|
        app["source_path"] = fixtures
      end

      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert dependency_report
      assert_equal fixtures, dependency_report.target.path
    end

    it "reports whether a dependency is allowed" do
      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      refute dependency_report["allowed"]

      config.apps.each do |app|
        app.review({
          "type" => TestSourceWithDependencyVersionNames.type,
          "name" => TestSource::DEFAULT_DEPENDENCY_NAME,
          "version" => TestSource::DEPENDENCY_VERSION
        }, at_version: true)
      end

      reporter.report.all_reports.clear

      run_command

      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert dependency_report["allowed"]
    end

    it "reports a cached record's recorded license" do
      run_command
      reports = reporter.report.all_reports
      dependency_report = reports.find { |report| report.target.is_a?(Licensed::Dependency) }
      assert_equal "mit", dependency_report["license"]
    end

    describe "with multiple apps" do
      let(:apps) do
        [
          {
            "name" => "app1",
            "cache_path" => "vendor/licenses/app1",
            "source_path" => Dir.pwd
          },
          {
            "name" => "app2",
            "cache_path" => "vendor/licenses/app2",
            "source_path" => Dir.pwd
          }
        ]
      end

      it "verifies dependencies for all apps" do
        run_command
        apps.each do |app|
          assert reporter.report.reports.find { |report| report.name == app["name"] }
        end
      end
    end
  end

  describe "with stale cached records" do
    let(:unused_record_file_path) do
      app = config.apps.first
      source = app.sources.first
      File.join(app.cache_path, source.class.type, "unused.#{Licensed::DependencyRecord::EXTENSION}")
    end

    before do
      # generate artifacts needed for the status command to normally pass
      # in order to validate that the command passes or fails depending on
      # the stale_records_action config setting
      generate_metadata_files
      config.apps.each do |app|
        app.allow "mit"
      end

      FileUtils.mkdir_p File.dirname(unused_record_file_path)
      File.write(unused_record_file_path, "")
    end

    after do
      config.apps.each do |app|
        FileUtils.rm_rf app.cache_path
      end
    end

    it "reports an error on stale cached records when configured" do
      command_config["stale_records_action"] = "error"

      refute run_command

      assert reporter.report.errors.include?("Stale dependency record found: #{unused_record_file_path}")
      refute reporter.report.warnings.include?("Stale dependency record found: #{unused_record_file_path}")
    end

    it "reports a warning on stale cached records when unconfigured" do
      assert run_command

      refute reporter.report.errors.include?("Stale dependency record found: #{unused_record_file_path}")
      assert reporter.report.warnings.include?("Stale dependency record found: #{unused_record_file_path}")
    end

    it "reports a warning on stale cached records when configured" do
      command_config["stale_records_action"] = "warn"

      assert run_command

      refute reporter.report.errors.include?("Stale dependency record found: #{unused_record_file_path}")
      assert reporter.report.warnings.include?("Stale dependency record found: #{unused_record_file_path}")
    end

    it "ignores stale cached records when configured" do
      command_config["stale_records_action"] = "ignore"

      assert run_command

      refute reporter.report.errors.include?("Stale dependency record found: #{unused_record_file_path}")
      refute reporter.report.warnings.include?("Stale dependency record found: #{unused_record_file_path}")
    end
  end
end
