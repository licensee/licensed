# frozen_string_literal: true
require "test_helper"
require "tmpdir"
require "fileutils"

if Licensed::Shell.tool_available?("npm")
  describe Licensed::Sources::NPM do
    let(:config) { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd }) }
    let(:fixtures) { File.expand_path("../../fixtures/npm", __FILE__) }
    let(:source) { Licensed::Sources::NPM.new(config) }
    let(:version) { Gem::Version.new(Licensed::Shell.execute("npm", "-v")) }

    describe "enabled?" do
      it "is true if package.json exists" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            File.write "package.json", ""
            assert source.enabled?
          end
        end
      end

      it "is false no npm configs exist" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            refute source.enabled?
          end
        end
      end
    end

    describe "dependencies" do
      it "includes declared dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "autoprefixer" }
          assert dep
          assert_equal "npm", dep.record["type"]
          assert_equal "5.2.0", dep.version
          if source.npm_version < Gem::Version.new("7.0.0")
            assert dep.record["homepage"]
          end
          assert dep.record["summary"]
        end
      end

      it "includes homepage information if available" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "amdefine" }
          assert dep
          assert_equal "npm", dep.record["type"]
          assert dep.record["homepage"]
        end
      end

      it "handles scoped dependency names" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "@github/query-selector" }
          assert dep
          assert_equal "1.0.3", dep.version
          if source.npm_version < Gem::Version.new("7.0.0")
            assert dep.record["homepage"]
          end
          assert dep.record["summary"]
        end
      end

      it "includes indirect dependencies" do
        Dir.chdir fixtures do
          assert source.dependencies.detect { |dep| dep.name == "autoprefixer" }
        end
      end

      it "does not include dev dependencies by default" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |dep| dep.name == "string.prototype.startswith" }
        end
      end

      it "includes dev dependencies if configured" do
        Dir.chdir fixtures do
          config["npm"] = { "production_only" => false }
          assert source.dependencies.detect { |dep| dep.name == "string.prototype.startswith" }
        end
      end

      it "does not include ignored dependencies" do
        Dir.chdir fixtures do
          config.ignore({ "type" => Licensed::Sources::NPM.type, "name" => "autoprefixer" })
          refute source.dependencies.detect { |dep| dep.name == "autoprefixer" }
        end
      end

      it "does not include missing indirect peer dependencies" do
        Dir.chdir fixtures do
          # peer dependency of @optimizely/js-sdk-datafile-manager, which is
          # an indirect dependency through @optimizely/optimizely-sdk
          # this checks the combination of being set in peerDependencies + `"missing": true`
          refute source.dependencies.detect { |dep| dep.name == "@react-native-community/async-storage" }

          # peer dependency of node-fetch
          # this checks the combination of being set in peerDependencies,
          # + peerDependencyMetadata `"optional": true`, + empty dependency data
          refute source.dependencies.detect { |dep| dep.name == "encoding" }
        end
      end

      it "raises a Licensed::Sources::Source:Error if npm list returns invalid JSON" do
        Dir.chdir fixtures do
          source.stubs(:package_metadata_command).returns("")
          assert_raises Licensed::Sources::Source::Error do
            source.dependencies
          end
        end
      end

      describe "with multiple instances of a dependency" do
        it "includes version in the dependency name for multiple unique versions" do
          Dir.chdir fixtures do
            graceful_fs_dependencies = source.dependencies.select { |dep| dep.name == "graceful-fs" }
            assert_empty graceful_fs_dependencies

            graceful_fs_dependencies = source.dependencies.select { |dep| dep.name =~ /graceful-fs/ }
            assert_equal 2, graceful_fs_dependencies.size
            graceful_fs_dependencies.each do |dependency|
              assert_equal "#{dependency.record["name"]}-#{dependency.version}", dependency.name
            end
          end
        end

        it "does not include version in the dependency name for a single unique version" do
          Dir.chdir fixtures do
            dep = source.dependencies.detect { |d| d.name == "wrappy" }
            assert_equal "wrappy", dep.name
          end
        end
      end

      describe "from a workspace" do
        let(:fixtures) { File.expand_path("../../fixtures/npm/packages/a", __FILE__) }

        it "finds dependencies" do
          # workspaces will only work as expected with npm > 8.5.0
          skip if source.npm_version < Gem::Version.new("8.5.0")

          Dir.chdir fixtures do
            dep = source.dependencies.detect { |d| d.name == "callbackify" }
            assert dep
            assert_equal "npm", dep.record["type"]
            assert_equal "1.1.0", dep.version
          end
        end

        it "does not include the current workspace project" do
          # workspaces will only work as expected with npm > 8.5.0
          skip if source.npm_version < Gem::Version.new("8.5.0")

          Dir.chdir fixtures do
            refute source.dependencies.detect { |d| d.name == "licensed-fixtures-a" }
          end
        end
      end
    end

    describe "missing dependencies (glob is missing package)" do
      it "includes missing dependencies when yarn.lock is missing" do
        # this test is incompatible with npm >=7
        skip if source.npm_version >= Gem::Version.new("7.0.0")

        Dir.mktmpdir do |dir|
          FileUtils.cp_r(fixtures, dir)
          dir = File.join(dir, "npm")
          FileUtils.rm_rf(File.join(dir, "node_modules/glob"))

          Dir.chdir dir do
            assert source.dependencies.detect { |dep| dep.name == "autoprefixer" }
            assert source.dependencies.detect { |dep| dep.name == "glob" }
          end
        end
      end

      it "excludes missing dependencies when yarn.lock is present" do
        # this test is incompatible with npm >=7
        skip if source.npm_version >= Gem::Version.new("7.0.0")

        Dir.mktmpdir do |dir|
          FileUtils.cp_r(fixtures, dir)
          dir = File.join(dir, "npm")
          FileUtils.rm_rf(File.join(dir, "node_modules/glob"))
          File.write(File.join(dir, "yarn.lock"), "")

          Dir.chdir dir do
            assert source.dependencies.detect { |dep| dep.name == "autoprefixer" }
            refute source.dependencies.detect { |dep| dep.name == "glob" }
          end
        end
      end

      it "raises Licensed::Sources::Source::Error on missing dependencies" do
        # this test is incompatible with npm <7, >=7.12.0 (possibly earlier versions as well, I haven't been able to verify)
        skip if source.npm_version < Gem::Version.new("7.0.0")
        skip if source.npm_version >= Gem::Version.new("7.12.0")

        Dir.mktmpdir do |dir|
          FileUtils.cp_r(fixtures, dir)
          dir = File.join(dir, "npm")
          FileUtils.rm_rf(File.join(dir, "node_modules/glob"))

          Dir.chdir dir do
            error = assert_raises Licensed::Sources::Source::Error do
              source.dependencies
            end

            assert error.message.include? "missing: glob@^7"
          end
        end
      end

      it "sets errors on missing dependencies" do
        # this test is incompatible with npm <7.12.0, (possibly earlier versions as well, I haven't been able to verify)
        skip if source.npm_version < Gem::Version.new("7.12.0")

        Dir.mktmpdir do |dir|
          FileUtils.cp_r(fixtures, dir)
          dir = File.join(dir, "npm")
          FileUtils.rm_rf(File.join(dir, "node_modules/glob"))

          Dir.chdir dir do
            glob = source.dependencies.find { |dep| dep.name == "glob" }
            assert glob.version
            assert_includes glob.errors, "missing: glob@^7.1.3, required by rimraf@2.7.1"
          end
        end
      end

      it "does not set errors on packages with reported problems that have a path" do
        # this test is incompatible with npm <7.12.0, (possibly earlier versions as well, I haven't been able to verify)
        skip if source.npm_version < Gem::Version.new("7.12.0")

        Dir.mktmpdir do |dir|
          FileUtils.cp_r(fixtures, dir)
          dir = File.join(dir, "npm")
          FileUtils.rm_rf(File.join(dir, "node_modules/glob"))

          Dir.chdir dir do
            # balanced-match is an extraneous dependency
            dep = source.dependencies.find { |dep| dep.name == "balanced-match" }
            assert dep
            assert_empty dep.errors
          end
        end
      end
    end
  end
end
