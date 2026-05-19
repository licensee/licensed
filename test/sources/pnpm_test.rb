# frozen_string_literal: true
require "test_helper"
require "tmpdir"
require "fileutils"

if Licensed::Shell.tool_available?("pnpm")
  describe Licensed::Sources::PNPM do
    let(:config) { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd }) }
    let(:fixtures) { File.expand_path("../../fixtures/pnpm", __FILE__) }
    let(:source) { Licensed::Sources::PNPM.new(config) }

    it "includes dependency versions in the name identifier" do
      assert Licensed::Sources::PNPM.require_matched_dependency_version
    end

    describe "enabled?" do
      it "is true if pnpm-lock.yaml exists" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            File.write "pnpm-lock.yaml", ""
            assert source.enabled?
          end
        end
      end

      it "is false no pnpm configuration exists" do
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
          dep = source.dependencies.detect { |d| d.name == "autoprefixer@5.2.0" }
          assert dep
          assert_equal "pnpm", dep.record["type"]
          assert_equal "5.2.0", dep.version
          assert dep.record["homepage"]
          assert dep.record["summary"]
        end
      end

      it "includes homepage information if available" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "amdefine@1.0.1" }
          assert dep
          assert_equal "pnpm", dep.record["type"]
          assert dep.record["homepage"]
        end
      end

      it "handles scoped dependency names" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "@github/query-selector@1.0.3" }
          assert dep
          assert_equal "1.0.3", dep.version
          assert dep.record["homepage"]
          assert dep.record["summary"]
        end
      end

      it "includes indirect dependencies" do
        Dir.chdir fixtures do
          assert source.dependencies.detect { |dep| dep.name == "autoprefixer-core@5.2.1" }
        end
      end

      it "does not include dev dependencies by default" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |dep| dep.name == "string.prototype.startswith@0.2.0" }
        end
      end

      it "includes dev dependencies if configured" do
        Dir.chdir fixtures do
          config["pnpm"] = { "production_only" => false }
          assert source.dependencies.detect { |dep| dep.name == "string.prototype.startswith@0.2.0" }
        end
      end

      it "does not include ignored dependencies" do
        Dir.chdir fixtures do
          config.ignore({ "type" => Licensed::Sources::PNPM.type, "name" => "autoprefixer", "version" => "5.2.0" }, at_version: true)
          refute source.dependencies.detect { |dep| dep.name == "autoprefixer@5.2.0" }
        end
      end

      it "raises a Licensed::Sources::Source:Error if pnpm licenses list returns invalid JSON" do
        Dir.chdir fixtures do
          source.stubs(:package_metadata_command).returns("")
          assert_raises Licensed::Sources::Source::Error do
            source.dependencies
          end
        end
      end

      it "includes dependencies from workspaces" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "callbackify@1.1.0" }
          assert dep
          assert_equal "pnpm", dep.record["type"]
          assert_equal "1.1.0", dep.version
        end
      end

      it "does not include workspace projects" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |d| d.name == "licensed-fixtures@1.0.0" }
          refute source.dependencies.detect { |d| d.name == "licensed-fixtures-a@1.0.0" }
        end
      end
    end
  end
end
