# frozen_string_literal: true
require "test_helper"
require "tmpdir"

if Licensed::Shell.tool_available?("bundle")
  describe Licensed::Sources::Bundler do
    let(:fixtures) { File.expand_path("../../fixtures/bundler", __FILE__) }
    let(:source_config) { Hash.new }
    let(:config) { Licensed::AppConfiguration.new({ "name" => "bundler_test", "source_path" => Dir.pwd }, "bundler" => source_config) }
    let(:source) { Licensed::Sources::Bundler.new(config) }

    describe "enabled?" do
      it "is true if Gemfile.lock exists" do
        Dir.chdir(fixtures) do
          assert source.enabled?
        end
      end

      it "is true if gems.locked exists" do
        Dir.mktmpdir do |tmp|
          Dir.chdir(tmp) do
            File.write("gems.rb", "")
            File.write("gems.locked", "")

            assert source.enabled?
          end
        end
      end

      it "is false no Gemfile.lock exists" do
        Dir.chdir(Dir.tmpdir) do
          refute source.enabled?
        end
      end
    end

    describe "dependencies" do
      it "does not include the source project" do
        Dir.chdir(fixtures) do
          config["name"] = "semantic"
          refute source.dependencies.find { |d| d.name == "semantic" }
        end
      end

      it "finds dependencies from Gemfile" do
        Dir.chdir(fixtures) do
          dep = source.dependencies.find { |d| d.name == "semantic" }
          assert dep
          assert_equal "1.6.0", dep.version
        end
      end

      it "finds platform-specific dependencies" do
        Dir.chdir(fixtures) do
          assert source.dependencies.find { |d| d.name == "nokogiri" }
        end
      end

      it "finds dependencies from path sources" do
        Dir.chdir(fixtures) do
          dep = source.dependencies.find { |d| d.name == "pathed-gem-fixture" }
          assert dep
          assert_equal "0.0.1", dep.version
        end
      end

      it "finds dependencies from git sources" do
        Dir.chdir(fixtures) do
          assert source.dependencies.find { |d| d.name == "thor" }
        end
      end

      it "includes bundler as a dependency when explicitly listed" do
        Dir.chdir(fixtures) do
          assert source.dependencies.find { |d| d.name == "bundler" }
        end
      end

      it "does not include bundler as a dependency when not explicitly listed" do
        source_config["without"] = "bundler"
        Dir.chdir(fixtures) do
          assert_nil source.dependencies.find { |d| d.name == "bundler" }
        end
      end

      describe "with excluded groups in the configuration" do
        let(:source_config) { { "without" => "exclude" } }

        it "ignores gems in the excluded groups" do
          Dir.chdir(fixtures) do
            assert_nil source.dependencies.find { |d| d.name == "i18n" }
          end
        end

        it "does not ignore gems from development and test" do
          Dir.chdir(fixtures) do
            # test
            dep = source.dependencies.find { |d| d.name == "minitest" }
            assert dep
            assert_equal "5.11.3", dep.version

            # dev
            dep = source.dependencies.find { |d| d.name == "tzinfo" }
            assert dep
            assert_equal "1.2.5", dep.version
          end
        end
      end

      it "ignores gems from development and test by default" do
        Dir.chdir(fixtures) do
          # test
          assert_nil source.dependencies.find { |d| d.name == "minitest" }

          # dev
          assert_nil source.dependencies.find { |d| d.name == "tzinfo" }
        end
      end

      it "ignores gems from bundler-configured 'without' groups" do
        Dir.chdir(fixtures) do
          assert_nil source.dependencies.find { |d| d.name == "json" }
        end
      end

      it "ignores local gemspecs" do
        Dir.chdir(fixtures) do
          assert_nil source.dependencies.find { |d| d.name == "licensed" }
        end
      end

      it "finds license metadata when gems are shipped without a gemspec" do
        Dir.chdir(fixtures) do
          dep = source.dependencies.find { |d| d.name == "aws-sdk-core" }
          assert dep
          assert_equal "3.39.0", dep.version
          assert_equal "apache-2.0", dep.license_key
        end
      end
    end

    describe "#with_application_environment" do
      it "resets the Bundler environment" do
        begin
          original_gem_home, ENV["GEM_HOME"] = ENV["GEM_HOME"], "foo"
          Dir.chdir(fixtures) do
            source.with_application_environment do
              refute_equal "foo", ENV["GEM_HOME"]
            end
          end
        ensure
          ENV["GEM_HOME"] = original_gem_home
        end
      end

      it "does not reset Bundler environment when the correct environment is already set" do
        begin
          original_gem_home, ENV["GEM_HOME"] = ENV["GEM_HOME"], "foo"
          original_bundle_gemfile, ENV["BUNDLE_GEMFILE"] = ENV["BUNDLE_GEMFILE"], source.config.source_path.join("Gemfile").to_s
          Dir.chdir(fixtures) do
            source.with_application_environment do
              assert_equal "foo", ENV["GEM_HOME"]
            end
          end
        ensure
          ENV["BUNDLE_GEMFILE"] = original_bundle_gemfile
          ENV["GEM_HOME"] = original_gem_home
        end
      end

      it "reloads the Bundler runtime to the applications configured source_path" do
        Dir.chdir(fixtures) do
          refute_equal config.source_path, ::Bundler.load.root
          source.with_application_environment do
            assert_equal config.source_path, ::Bundler.load.root
          end
          refute_equal config.source_path, ::Bundler.load.root
        end
      end
    end
  end
end
