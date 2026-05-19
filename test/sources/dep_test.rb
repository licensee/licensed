# frozen_string_literal: true
require "test_helper"
require "tmpdir"

describe Licensed::Sources::Dep do
  let(:fixtures) { File.expand_path("../../fixtures/dep/src/test", __FILE__) }
  let(:config) { Licensed::AppConfiguration.new({ "dep" => { "allow_ignored" => true }, "source_path" => Dir.pwd }) }
  let(:source) { Licensed::Sources::Dep.new(config) }

  describe "enabled?" do
    it "is true if Gopkg files exist" do
      Dir.chdir(fixtures) do
        assert source.enabled?
      end
    end

    it "is false if Gopkg files do not exist" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          refute source.enabled?
        end
      end
    end
  end

  describe "packages" do
    it "returns package information from Gopkg.lock" do
      Dir.chdir fixtures do
        package = source.packages.detect { |pkg| pkg[:name] == "github.com/gorilla/context" }
        assert package
        assert "github.com/gorilla/context", package[:project]
        assert package[:version]
      end
    end
  end


  describe "dependencies" do
    it "includes dependent packages" do
      Dir.chdir fixtures do
        dep = source.dependencies.detect { |d| d.name == "github.com/gorilla/context" }
        assert dep
        assert_equal "dep", dep.record["type"]
        assert_equal "https://pkg.go.dev/github.com/gorilla/context", dep.record["homepage"]
      end
    end

    if Licensed::Shell.tool_available?("go")
      it "doesn't include vendored dependencies from the go std library" do
        Dir.chdir fixtures do
          refute source.dependencies.any? { |d| d.name == "golang.org/x/net/http2/hpack" }
        end
      end
    end

    it "includes vendored dependencies from the go std library if go is not available" do
      Licensed::Shell.stubs(:tool_available?).returns(false)
      Dir.chdir fixtures do
        assert source.dependencies.any? { |d| d.name == "golang.org/x/net/http2/hpack" }
      end
    end
  end
end
