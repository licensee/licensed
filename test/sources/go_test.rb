# frozen_string_literal: true
require "test_helper"
require "tmpdir"

if Licensed::Shell.tool_available?("go")
  describe Licensed::Sources::Go do
    let(:gopath) { File.expand_path("../../fixtures/go", __FILE__) }
    let(:fixtures) { File.join(gopath, "src/test") }
    let(:root) { File.join(gopath, "src/test") }
    let(:config) { Licensed::AppConfiguration.new({ "go" => { "GOPATH" => gopath }, "source_path" => fixtures, "root" => root }) }
    let(:source) { Licensed::Sources::Go.new(config) }

    describe "enabled?" do
      it "is true if go source is available" do
        Dir.chdir(fixtures) do
          assert source.enabled?
        end
      end

      it "is false if go source is not available" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            refute source.enabled?
          end
        end
      end
    end

    describe "gopath" do
      it "works with an absolute configuration path" do
        assert_equal gopath, source.gopath
      end

      it "works with a configuration path relative to repository root" do
        config["go"]["GOPATH"] = "../.."
        assert_equal gopath, source.gopath
      end

      it "works with an expandable configuration path" do
        config["go"]["GOPATH"] = "~"
        assert_equal File.expand_path("~"), source.gopath
      end

      it "uses ENV['GOPATH'] if configured value not available" do
        begin
          original_gopath = ENV["GOPATH"]
          ENV["GOPATH"] = gopath
          config.delete("go")

          assert_equal gopath, source.gopath

          # sanity test that finding dependencies using ENV works
          Dir.chdir fixtures do
            assert source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru" }
          end
        ensure
          ENV["GOPATH"] = original_gopath
        end
      end

      it "uses `go env GOPATH` if ENV['GOPATH'] and configured values aren't available" do
        begin
          original_gopath = ENV["GOPATH"]
          ENV["GOPATH"] = nil
          config.delete("go")

          assert_equal Licensed::Shell.execute("go", "env", "GOPATH"), source.gopath

          # sanity test that finding dependencies using go env GOPATH works
          Dir.chdir fixtures do
            assert source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru" }
          end
        ensure
          ENV["GOPATH"] = original_gopath
        end
      end
    end

    describe "dependencies" do
      it "does not include the current package" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name.end_with?("test") }
          refute dep
        end
      end

      it "does not include any local, non vendored packages" do
        Dir.chdir fixtures do
          refute source.dependencies.detect { |d| d.name == "test/pkg/world" }
        end
      end

      it "includes direct dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru" }
          assert dep
          assert_equal "go", dep.record["type"]
          assert dep.record["homepage"]
          assert dep.record["summary"]
          assert_equal "v0.5.0", dep.version
        end
      end

      it "includes indirect dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru/simplelru" }
          assert dep
          assert_equal "go", dep.record["type"]
          assert dep.record["homepage"]
        end
      end

      it "doesn't include dependencies from the go std library" do
        Dir.chdir fixtures do
          refute source.dependencies.any? { |d| d.name == "runtime" }
        end
      end

      it "doesn't include vendored dependencies from the go std library" do
        Dir.chdir fixtures do
          refute source.dependencies.any? { |d| d.name == "golang.org/x/net/http2/hpack" }
        end
      end

      it "searches for license files in the folder hierarchy up to GOPATH" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru/simplelru" }
          assert dep
          license_path = File.join(dep.path, "../LICENSE")
          license = dep.record.licenses.find { |l| l.sources.any? { |s| s =~ /golang-lru@[^\/]*\/LICENSE/ } }
          assert license
          assert_equal File.read(license_path), license.text
        end
      end

      describe "with vendored go modules" do
        before do
          Dir.chdir fixtures do
            Licensed::Shell.execute("go", "mod", "vendor")
          end
          config["go"]["mod"] = "vendor"
        end

        after do
          FileUtils.rm_rf(File.join(fixtures, "vendor"))
        end

        it "searches for license files under the vendor folder for vendored dependencies" do
          Dir.chdir fixtures do
            dep = source.dependencies.detect { |d| d.name == "github.com/davecgh/go-spew/spew" }
            assert dep

            # find the license one directory higher
            license_path = File.join(fixtures, "vendor/github.com/davecgh/go-spew/LICENSE")
            license = dep.record.licenses.find { |l| l.sources == ["go-spew/LICENSE"] }
            assert license
            assert_equal File.read(license_path), license.text

            # do not find the license outside the vendor folder
            assert_nil dep.record.licenses.find { |l| l.sources == ["LICENSE"] }
          end
        end

        it "sets the error field on a missing dependency" do
          FileUtils.rm_rf(File.join(fixtures, "vendor/github.com/hashicorp/golang-lru"))
          Dir.chdir fixtures do
            dep = source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru" }
            assert dep
            assert dep.errors.any? { |e| e =~ /cannot find (?:package|module providing package).*github\.com\/hashicorp\/golang-lru/im }
          end
        end
      end

      describe "from a subfolder source_path" do
        let(:fixtures) { File.join(gopath, "src/test/cmd/command") }

        it "includes direct dependencies" do
          Dir.chdir fixtures do
            dep = source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru" }
            assert dep
            assert_equal "go", dep.record["type"]
            assert dep.record["homepage"]
            assert dep.record["summary"]
          end
        end

        it "includes indirect dependencies" do
          Dir.chdir fixtures do
            dep = source.dependencies.detect { |d| d.name == "github.com/hashicorp/golang-lru/simplelru" }
            assert dep
            assert_equal "go", dep.record["type"]
            assert dep.record["homepage"]
          end
        end
      end
    end

    describe "search_root" do
      it "is nil for nil input" do
        assert_nil source.search_root(nil)
      end

      it "is the package module directory if available" do
        package = {
          "Module" => { "Dir" => "test" }
        }
        assert_equal "test", source.search_root(package)
      end

      it "is the vendor folder if the package is vendored" do
        package = { "Dir" => "#{config.root}/vendor/package/path" }
        assert_equal "#{config.root}/vendor", source.search_root(package)
      end

      it "is package['Root'] if given" do
        package = {
          "Dir" => "test/path",
          "Root" => "test"
        }
        assert_equal "test", source.search_root(package)
      end

      it "is the available gopath value if gopath directory is an ancestor of the package" do
        source.stubs(:gopath).returns("test")
        package = { "Dir" => "test/path" }
        assert_equal "test", source.search_root(package)
      end

      it "is nil if a search root cannot be found" do
        source.stubs(:gopath).returns("/go")
        package = { "Dir" => "test/path" }
        assert_nil source.search_root(package)
      end
    end

    describe "go_std_package?" do
      let(:root_package_import_path) { "test" }

      before do
        source.stubs(:root_package).returns("ImportPath" => root_package_import_path)
        source.stubs(:go_std_packages).returns([
          "package/1",
          "package/2",
          "vendor/package/3",
          "vendor/golang_org/package/4"
        ])
      end

      it "returns false for a nil package" do
        refute source.go_std_package?(nil)
      end

      it "returns true if package self-identifies as standard" do
        package = { "Standard" => true }
        assert source.go_std_package?(package)
      end

      it "returns false unless the package contains an import path" do
        package = {}
        refute source.go_std_package?(package)
      end

      it "returns true if the import path matches 'go list std'" do
        package = { "ImportPath" => "package/1" }
        assert source.go_std_package?(package)
      end

      it "returns false for unvendored import paths not matching 'go list std'" do
        package = { "ImportPath" => "package/no_match" }
        refute source.go_std_package?(package)
      end

      it "returns true if the vendored import path matches 'go list std'" do
        package = {
          "ImportPath" => "#{root_package_import_path}/vendor/package/3",
          "Dir" => "#{root}/vendor/package/3"
        }
        assert source.go_std_package?(package)
      end

      it "returns true if the underscore vendored import path matches 'go list std'" do
        package = {
          "ImportPath" => "#{root_package_import_path}/vendor/golang.org/package/4",
          "Dir" => "#{root}/vendor/golang.org/package/4"
        }
        assert source.go_std_package?(package)
      end

      it "returns true if the non-vendored import path matches 'go list std'" do
        package = {
          "ImportPath" => "#{root_package_import_path}/vendor/package/2",
          # determining the non-vendored path requires the "Dir" value to be set
          "Dir" => "#{root}/vendor/package/2"
        }
        assert source.go_std_package?(package)
      end

      it "returns true if the import path with 'vendor/' matches `go list std`" do
        package = { "ImportPath" => "package/3" }
        assert source.go_std_package?(package)
      end

      it "returns false if vendored import path does't match 'go list std'" do
        package = { "ImportPath" => "#{root_package_import_path}/vendor/package/5" }
        refute source.go_std_package?(package)
      end
    end

    describe "vendored_path_parts" do
      it "returns nil for a nil package" do
        assert_nil source.vendored_path_parts(nil)
      end

      it "returns nil if the package doesn't contain a Dir value" do
        assert_nil source.vendored_path_parts({})
      end

      it "returns nil if the package isn't vendored" do
        package = { "Dir" => "#{root}/pkg/foo" }
        assert_nil source.vendored_path_parts(package)
      end

      it "returns nil if the package directory doesn't start with the config root" do
        package = { "Dir" => "#{gopath}/vendor/github.com/owner/repo" }
        assert_nil source.vendored_path_parts(package)
      end

      it "returns nil if the package name is vendor" do
        package = { "Dir" => "#{root}/pkg/vendor" }
        assert_nil source.vendored_path_parts(package)
      end

      it "returns the import path for a vendored package at project root" do
        package = { "Dir" => "#{root}/vendor/github.com/owner/repo" }
        match = source.vendored_path_parts(package)
        assert match
        assert_equal "#{root}/vendor", match[:vendor_path]
        assert_equal "github.com/owner/repo", match[:import_path]
      end

      it "returns the import path for a vendored package at project subfolder" do
        package = { "Dir" => "#{root}/sub_module/vendor/github.com/owner/repo" }
        match = source.vendored_path_parts(package)
        assert match
        assert_equal "#{root}/sub_module/vendor", match[:vendor_path]
        assert_equal "github.com/owner/repo", match[:import_path]
      end
    end

    describe "non_vendored_import_path" do
      it "returns nil if package is nil" do
        assert_nil source.non_vendored_import_path(nil)
      end

      it "returns the non-vendored import path for a vendored package" do
        # it should never happen that the import path is different from the
        # directory path... but this tests that the right value is used
        package = {
          "ImportPath" => "github.com/owner/repo2",
          "Dir" => "#{root}/vendor/github.com/owner/repo"
        }

        assert_equal "github.com/owner/repo", source.non_vendored_import_path(package)
      end

      it "returns the package's ImportPath property for a non-vendored package" do
        # it should never happen that the import path is different from the
        # directory path... but this tests that the right value is used
        package = {
          "ImportPath" => "test/pkg/foo/bar2",
          "Dir" => "#{root}/pkg/foo/bar"
        }

        assert_equal "test/pkg/foo/bar2", source.non_vendored_import_path(package)
      end
    end
  end
end
