# frozen_string_literal: true
require "test_helper"
require "fileutils"
require "open3"
require "tmpdir"

describe "Development scripts" do
  let(:root) { File.expand_path("..", __dir__) }

  def copy_script(directory, relative_path)
    target = File.join(directory, relative_path)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(File.join(root, relative_path), target)
    target
  end

  def run_setup(exit_statuses)
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "setup-test.gemspec"), <<~GEMSPEC)
        Gem::Specification.new do |spec|
          spec.name = "setup-test"
          spec.version = "0.0.0"
        end
      GEMSPEC
      scripts = File.join(directory, "script/source-setup")
      FileUtils.mkdir_p(scripts)
      exit_statuses.each do |name, exit_status|
        script = File.join(scripts, name)
        File.write(script, "#!/bin/sh\nprintf '%s:%s\\n' '#{name}' \"$1\" >> attempts\nexit #{exit_status}\n")
        File.chmod(0o755, script)
      end

      output, error, status = Open3.capture3(
        { "BUNDLE_GEMFILE" => File.join(root, "Gemfile") },
        "bundle", "exec", "rake", "--rakefile", File.join(root, "Rakefile"), "setup[-f]",
        chdir: directory
      )
      attempts = File.join(directory, "attempts")
      attempted_scripts = File.file?(attempts) ? File.readlines(attempts, chomp: true) : []
      yield output, error, status, attempted_scripts
    end
  end

  it "skips unavailable setup tools without failing or skipping later scripts" do
    run_setup("01_unavailable" => 127, "02_success" => 0) do |output, error, status, attempts|
      assert status.success?, "#{output}\n#{error}"
      assert_equal ["01_unavailable:-f", "02_success:-f"], attempts
      assert_includes output, "Skipped script/source-setup/01_unavailable."
      assert_includes output, "Completed script/source-setup/02_success."
      refute_includes error, "Setup failed:"
    end
  end

  it "attempts every setup script before exiting with all failures summarized" do
    exit_statuses = { "01_failure" => 1, "02_unavailable" => 127, "03_failure" => 42, "04_success" => 0 }
    run_setup(exit_statuses) do |output, error, status, attempts|
      refute status.success?
      assert_equal 1, status.exitstatus
      assert_equal exit_statuses.keys.map { |name| "#{name}:-f" }, attempts
      assert_includes output, "Skipped script/source-setup/02_unavailable."
      assert_includes output, "Completed script/source-setup/04_success."
      summary = error.lines.find { |line| line.start_with?("Setup failed:") }
      assert_equal "Setup failed: script/source-setup/01_failure, script/source-setup/03_failure", summary&.strip
    end
  end

  it "loads local settings before running build, setup, tests, or source preparation" do
    Dir.mktmpdir do |directory|
      copy_script(directory, "script/development-env")
      File.write(File.join(directory, ".licensed-dev-env"), "printf 'local settings loaded\\n'\nexit 0\n")

      source_scripts = Dir.glob(File.join(root, "script/source-setup/**/*"))
        .select { |path| File.file?(path) }
        .map { |path| path.delete_prefix("#{root}/") }
      (%w[script/cibuild script/setup script/test] + source_scripts).each do |relative_path|
        script = copy_script(directory, relative_path)
        output, error, status = Open3.capture3(script, chdir: Dir.tmpdir)
        assert status.success?, error
        assert_equal "local settings loaded\n", output
      end
    end
  end

  it "preserves the caller environment when local settings are absent" do
    Dir.mktmpdir do |directory|
      loader = copy_script(directory, "script/development-env")
      output, error, status = Open3.capture3(
        { "BASE_PATH" => directory, "LICENSED_TEST_ENV" => "caller" },
        "sh", "-c", '. "$1"; printf "%s" "$LICENSED_TEST_ENV"', "sh", loader
      )
      assert status.success?, error
      assert_equal "caller", output
    end
  end

  it "repairs registered submodules with missing worktrees and supports repeated setup" do
    Dir.mktmpdir do |directory|
      copy_script(directory, "script/development-env")
      script = copy_script(directory, "script/source-setup/git_submodule")
      FileUtils.cp(File.join(root, "LICENSE"), directory)
      fixtures = File.join(directory, "test/fixtures/git_submodule")
      FileUtils.mkdir_p(fixtures)
      environment = {
        "GIT_AUTHOR_NAME" => "Licensed tests",
        "GIT_AUTHOR_EMAIL" => "licensed@example.com",
        "GIT_COMMITTER_NAME" => "Licensed tests",
        "GIT_COMMITTER_EMAIL" => "licensed@example.com"
      }

      output, error, status = Open3.capture3(environment, script)
      assert status.success?, "#{output}\n#{error}"

      submodule = File.join(fixtures, "submodule")
      output, error, status = Open3.capture3("git", "-C", submodule, "submodule", "deinit", "-f", "--", "vendor/nested")
      assert status.success?, "#{output}\n#{error}"
      refute File.exist?(File.join(submodule, "vendor/nested/LICENSE"))

      2.times do
        output, error, status = Open3.capture3(environment, script)
        assert status.success?, "#{output}\n#{error}"
        assert File.file?(File.join(submodule, "vendor/nested/LICENSE"))
        assert File.file?(File.join(fixtures, "project/vendor/submodule/vendor/nested/LICENSE"))
      end
    end
  end
end
