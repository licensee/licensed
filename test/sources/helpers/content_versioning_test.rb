# frozen_string_literal: true
require "test_helper"

describe Licensed::Sources::ContentVersioning do
  let(:fixtures) { File.expand_path("../../../fixtures/config", __FILE__) }
  let(:config) { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd }) }
  let(:helper) do
    obj = mock.extend Licensed::Sources::ContentVersioning
    obj.stubs(:config).returns(config)
    obj
  end


  describe "#contents_version" do
    it "handles a content hashing strategy" do
      config["version_strategy"] = Licensed::Sources::ContentVersioning::CONTENTS
      helper.expects(:contents_hash).with(["path1", "path2"]).returns("version")
      helper.expects(:git_version).never
      assert_equal "version", helper.contents_version("path1", "path2")
    end

    it "handles a git commit SHA strategy" do
      config["version_strategy"] = Licensed::Sources::ContentVersioning::GIT
      helper.expects(:contents_hash).never
      helper.expects(:git_version).with(["path1", "path2"]).returns("version")
      assert_equal "version", helper.contents_version("path1", "path2")
    end
  end

  describe "#version_strategy" do
    it "specifies content hashing if configured" do
      config["version_strategy"] = Licensed::Sources::ContentVersioning::CONTENTS
      assert_equal Licensed::Sources::ContentVersioning::CONTENTS, helper.version_strategy
    end

    it "specifies git version if configured" do
      config["version_strategy"] = Licensed::Sources::ContentVersioning::GIT
      assert_equal Licensed::Sources::ContentVersioning::GIT, helper.version_strategy
    end

    it "defaults to git version if not configured and git is available" do
      Licensed::Git.stubs(:available?).returns(true)
      assert_equal Licensed::Sources::ContentVersioning::GIT, helper.version_strategy
    end

    it "defaults to content hashing if not configured and git is not available" do
      Licensed::Git.stubs(:available?).returns(false)
      assert_equal Licensed::Sources::ContentVersioning::CONTENTS, helper.version_strategy
    end
  end

  describe "#git_version" do
    it "gets a hash for the latest commit for the set of paths" do
      Dir.chdir fixtures do
        # the hash for "." in a folder should identify the latest commit
        # regardless of what other files from that folder are included
        assert_equal Licensed::Git.version("."), helper.git_version(Dir["*"].concat(["."]))
      end
    end

    it "handles files not tracked by git" do
      dir = File.expand_path("../../../bin", fixtures)
      tmp = File.join(dir, "tmp")

      begin
        Dir.mkdir dir unless File.exist?(dir)
        FileUtils.touch tmp
        Dir.chdir dir do
          assert_nil helper.git_version(Dir["*"])
        end
      ensure
        File.unlink(tmp) if tmp && File.exist?(tmp)
      end
    end

    it "handles empty arrays" do
      assert_nil helper.git_version([])
    end

    it "handles nil input" do
      assert_nil helper.git_version(nil)
    end
  end

  describe "#contents_hash" do
    it "gets a hash representing the contents of relative paths" do
      Dir.chdir fixtures do
        refute_nil helper.contents_hash(Dir["*"])
      end
    end

    it "gets a hash representing the contents of absolute paths" do
      refute_nil helper.contents_hash(Dir["#{fixtures}/*"])
    end

    it "is agnostic to the order of paths provided" do
      Dir.chdir fixtures do
        assert_equal helper.contents_hash(["config.yml", "root.yml", "root_at_configuration.yml"]),
                     helper.contents_hash(["root_at_configuration.yml", "root.yml", "config.yml"])
      end
    end

    it "handles empty arrays" do
      assert_nil helper.contents_hash([])
    end

    it "handles nil input" do
      assert_nil helper.contents_hash(nil)
    end

    it "handles nil paths" do
      assert_nil helper.contents_hash([nil])
    end

    it "handles non-existant paths" do
      assert_nil helper.contents_hash(["#{fixtures}-bad"])
    end

    it "handles non-file paths" do
      assert_nil helper.contents_hash([fixtures])
    end
  end
end
