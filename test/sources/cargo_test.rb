# frozen_string_literal: true
require "test_helper"
require "tmpdir"

if Licensed::Shell.tool_available?("cargo")
  describe Licensed::Sources::Cargo do
    let(:fixtures) { File.expand_path("../../fixtures/cargo", __FILE__) }
    let(:config) { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd }) }
    let(:source) { Licensed::Sources::Cargo.new(config) }

    describe "enabled?" do
      it "is false if Cargo.toml does not exist" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            refute source.enabled?
          end
        end
      end

      it "is true if Cargo.toml exists" do
        Dir.chdir(fixtures) do
          assert source.enabled?
        end
      end
    end

    describe "dependencies" do
      it "does not include the current application" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |d| d.name == "app-0.1.0" }
        end
      end

      it "includes declared dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "time-0.3.2" }
          assert dep
          assert_equal "cargo", dep.record["type"]
          assert dep.record["homepage"]
          assert dep.record["summary"]
          assert dep.path
        end
      end

      it "includes transitive dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "libc-0.2.102" }
          assert dep
          assert_equal "cargo", dep.record["type"]
          assert dep.record["homepage"]
          assert dep.record["summary"]
          assert dep.path
        end
      end

      it "does not include dev dependencies" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |dep| dep.name == "criterion" }
        end
      end

      it "does not include not-installed optional dependencies" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |dep| dep.name == "time-macros" }
        end
      end
    end

    describe "cargo_metadata" do
      it "raises Licensed::Sources::Source::Error if the cargo JSON metadata can't be parsed" do
        Licensed::Shell.stubs(:execute).returns("")
        Dir.chdir fixtures do
          assert_raises Licensed::Sources::Source::Error do
            source.cargo_metadata
          end
        end
      end
    end

    describe "cargo_metadata_command" do
      it "applies a configured string metadata cli option" do
        Dir.chdir fixtures do
          config["cargo"] = { "metadata_options" => "--all-features" }
          Licensed::Shell.expects(:execute).with("cargo", "metadata", "--format-version=1", "--all-features")
          source.cargo_metadata_command
        end
      end

      it "applies a configured array of string metadata cli options" do
        Dir.chdir fixtures do
          config["cargo"] = { "metadata_options" => ["--all-features", "--filter-platform x86_64-pc-windows-msvc"] }
          Licensed::Shell.expects(:execute).with("cargo", "metadata", "--format-version=1", "--all-features", "--filter-platform", "x86_64-pc-windows-msvc")
          source.cargo_metadata_command
        end
      end
    end
  end
end
