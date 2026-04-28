# frozen_string_literal: true
require "test_helper"
require "fileutils"
require "rbconfig"
require "tmpdir"

describe Licensed do
  let(:root) { File.expand_path("..", __dir__) }

  describe "VERSION" do
    it "uses git describe when a gemspec version is not loaded" do
      with_git_describe("v1.2.3") do |env|
        out, status = ruby_output(env)

        assert status.success?, out
        assert_equal "1.2.3", out.strip
      end
    end

    it "uses the next patch version when git describe is past the latest tag" do
      with_git_describe("v1.2.3-4-gabc1234") do |env|
        out, status = ruby_output(env)

        assert status.success?, out
        assert_equal "1.2.4", out.strip
      end
    end

    it "uses the loaded gemspec version when available" do
      out, status = ruby_output({ "PATH" => "" }, <<~RUBY)
        Gem.loaded_specs["licensed"] = Gem::Specification.new do |spec|
          spec.name = "licensed"
          spec.version = "9.8.7"
        end
        require "licensed/version"
        puts Licensed::VERSION
      RUBY

      assert status.success?, out
      assert_equal "9.8.7", out.strip
    end

    it "uses Gemfile.lock when git describe is unavailable" do
      with_git_describe("fatal: No names found", status: 128) do |env|
        out, status = ruby_output(env)

        assert status.success?, out
        assert_equal File.read(File.join(root, "Gemfile.lock"))[/^    licensed \(([^)]+)\)$/, 1],
                     out.strip
      end
    end

    it "reports git describe errors" do
      without_lockfile do |dir|
        with_git_describe("fatal: No names found", status: 128) do |env|
          out, status = ruby_output(env, nil, load_root: dir)

          refute status.success?, out
          assert_includes out,
                          "Unable to determine licensed version: fatal: No names found"
        end
      end
    end

    it "reports when git is unavailable" do
      without_lockfile do |dir|
        out, status = ruby_output({ "PATH" => "" }, nil, load_root: dir)

        refute status.success?, out
        assert_includes out, "Unable to determine licensed version"
        assert_includes out, "git"
      end
    end

    it "uses git describe for the gemspec version" do
      with_git_describe("v5.05") do |env|
        out, status = ruby_output(env, <<~RUBY)
          Dir.chdir(#{root.inspect}) do
            puts Gem::Specification.load("licensed.gemspec").full_name
          end
        RUBY

        assert status.success?, out
        assert_equal "licensed-5.05", out.strip
      end
    end

    it "uses the next patch version for the gemspec version" do
      with_git_describe("v5.0.6-4-gabc1234") do |env|
        out, status = ruby_output(env, <<~RUBY)
          Dir.chdir(#{root.inspect}) do
            puts Gem::Specification.load("licensed.gemspec").full_name
          end
        RUBY

        assert status.success?, out
        assert_equal "licensed-5.0.7", out.strip
      end
    end
  end

  def ruby_output(env = {}, code = nil, load_root: root)
    if env.is_a?(String)
      code = env
      env = {}
    end

    Open3.capture2e(
      {
        "BUNDLE_BIN_PATH" => nil,
        "BUNDLE_GEMFILE" => nil,
        "BUNDLE_LOCKFILE" => nil,
        "BUNDLER_SETUP" => nil,
        "BUNDLER_VERSION" => nil,
        "GEM_HOME" => nil,
        "GEM_PATH" => nil,
        "RUBYLIB" => nil,
        "RUBYOPT" => nil
      }.merge(env),
      RbConfig.ruby,
      "-I#{File.join(load_root, "lib")}",
      "-e",
      code || "require \"licensed/version\"; puts Licensed::VERSION"
    )
  end

  def with_git_describe(version, status: 0)
    Dir.mktmpdir do |dir|
      git = File.join(dir, "git")
      File.write(git, <<~SH)
        #!/bin/sh
        if [ "$1" = "describe" ]; then
          printf '%s\\n' "#{version}"#{status.zero? ? "" : " >&2"}
          exit #{status}
        elif [ "$1" = "ls-files" ]; then
          printf 'licensed.gemspec\\0lib/licensed/version.rb\\0exe/licensed\\0'
        else
          exit 1
        fi
      SH
      File.chmod(0755, git)

      yield "PATH" => "#{dir}:#{ENV["PATH"]}"
    end
  end

  def without_lockfile
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p File.join(dir, "lib/licensed")
      FileUtils.cp File.join(root, "lib/licensed/version.rb"),
                   File.join(dir, "lib/licensed/version.rb")

      yield dir
    end
  end
end
