# frozen_string_literal: true
require "test_helper"

describe "licensed" do
  let(:root) { File.expand_path("../../", __FILE__) }
  let(:config_path) { File.join(root, "test/fixtures/cli/.licensed.yml") }

  before do
    Dir.chdir root
  end

  describe "cache" do
    it "exits 0" do
      _, status = Open3.capture2 "bundle exec exe/licensed cache -c #{config_path}"
      assert status.success?
    end

    it "exits 1 when a config file isn't found" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          _, _, status = Open3.capture3 "bundle exec exe/licensed cache"
          refute status.success?
        end
      end
    end

    it "accepts a path to a config file" do
      out, = Open3.capture2 "bundle exec exe/licensed cache -c #{config_path}"
      refute out =~ /Usage/i

      out, = Open3.capture2 "bundle exec exe/licensed cache --config #{config_path}"
      refute out =~ /Usage/i
    end
  end

  describe "status" do
    it "exits 1 when failing" do
      _, _, status = Open3.capture3 "bundle exec exe/licensed status -c #{config_path}"
      refute status.success?
    end

    it "exits 1 when a config file isn't found" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          _, _, status = Open3.capture3 "bundle exec exe/licensed status"
          refute status.success?
        end
      end
    end

    it "accepts a path to a config file" do
      out, = Open3.capture2 "bundle exec exe/licensed status -c #{config_path}"
      refute out =~ /Usage/i

      out, = Open3.capture2 "bundle exec exe/licensed status --config #{config_path}"
      refute out =~ /Usage/i
    end
  end

  describe "list" do
    it "exits 0" do
      _, status = Open3.capture2 "bundle exec exe/licensed list -c #{config_path}"
      assert status.success?
    end

    it "exits 1 when a config file isn't found" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          _, _, status = Open3.capture3 "bundle exec exe/licensed list"
          refute status.success?
        end
      end
    end

    it "accepts a path to a config file" do
      out, = Open3.capture2 "bundle exec exe/licensed list -c #{config_path}"
      refute out =~ /Usage/i

      out, = Open3.capture2 "bundle exec exe/licensed list --config #{config_path}"
      refute out =~ /Usage/i
    end
  end

  describe "version" do
    it "outputs the current licensed version" do
      expected_out = "#{Licensed::VERSION}\n"
      out, status = Open3.capture2 "bundle exec exe/licensed version"
      assert status.success?
      assert_equal expected_out, out.lines.last

      out, status = Open3.capture2 "bundle exec exe/licensed -v"
      assert status.success?
      assert_equal expected_out, out.lines.last

      out, status = Open3.capture2 "bundle exec exe/licensed --version"
      assert status.success?
      assert_equal expected_out, out.lines.last
    end
  end

  describe "missing subcommand" do
    it "exits 1 when a subcommand isn't defined" do
      _, _, status = Open3.capture3 "bundle exec exe/licensed verify"
      refute status.success?
    end
  end
end
