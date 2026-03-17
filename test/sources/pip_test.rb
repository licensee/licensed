# frozen_string_literal: true
require "test_helper"
require "fileutils"
require "tmpdir"

describe Licensed::Sources::Pip do
  class TestablePipSource < Licensed::Sources::Pip
    public :parse_package_info, :homepage
  end

  let(:config) { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd }) }
  let(:source) { TestablePipSource.new(config) }

  it "parses pip show continuation lines" do
    parsed = source.parse_package_info(
      <<~INFO
        Name: azure-core
        Project-URLs:
          Repository, https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core
      INFO
    )

    assert_equal(
      "Repository, https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core",
      parsed["Project-URLs"]
    )
  end

  it "falls back to Project-URLs when Home-page is empty" do
    homepage = source.homepage(
      {
        "Home-page" => "",
        "Project-URLs" => "Repository, https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core"
      }
    )

    assert_equal "https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core", homepage
  end

  it "prefers Home URL from Project-URLs even when listed last" do
    homepage = source.homepage(
      {
        "Home-page" => "",
        "Project-URLs" => [
          "Documentation, https://learn.microsoft.com/azure/",
          "Repository, https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core",
          "Home, https://azure.microsoft.com/en-us/products/"
        ].join("\n")
      }
    )

    assert_equal "https://azure.microsoft.com/en-us/products/", homepage
  end

  it "prefers Repository URL when Home is not present" do
    homepage = source.homepage(
      {
        "Home-page" => "",
        "Project-URLs" => [
          "Documentation, https://learn.microsoft.com/azure/",
          "Repository, https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core",
          "Source, https://example.com/source"
        ].join("\n")
      }
    )

    assert_equal "https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/core/azure-core", homepage
  end

  it "filters malformed and non-http Project-URLs entries" do
    homepage = source.homepage(
      {
        "Home-page" => "",
        "Project-URLs" => [
          "NoCommaEntry",
          "Documentation, ftp://learn.microsoft.com/azure/",
          "Documentation, https://learn.microsoft.com/azure/",
          "Source, not-a-url"
        ].join("\n")
      }
    )

    assert_equal "https://learn.microsoft.com/azure/", homepage
  end

  it "prefers Home-page when present" do
    homepage = source.homepage(
      {
        "Home-page" => "https://example.com/home",
        "Project-URLs" => "Repository, https://github.com/example/repo"
      }
    )

    assert_equal "https://example.com/home", homepage
  end

  it "returns nil when Project-URLs is a non-string value" do
    package = Hash.new(0)
    package["Home-page"] = ""

    assert_nil source.homepage(package)
  end

  it "finds lowercase dist-info directories for mixed-case package names" do
    Dir.mktmpdir do |dir|
      dist_info = File.join(dir, "pyjwt-2.12.0.dist-info")
      licenses = File.join(dist_info, "licenses")
      FileUtils.mkdir_p(licenses)

      config = Licensed::AppConfiguration.new({
        "source_path" => Dir.pwd,
        "python" => { "virtual_env_dir" => "test/fixtures/pip/venv" }
      })
      source = Licensed::Sources::Pip.new(config)

      path = source.send(
        :package_license_location,
        {
          "Name" => "PyJWT",
          "Version" => "2.12.0",
          "Location" => dir
        }
      )

      assert_equal licenses, path
    end
  end
end

if Licensed::Shell.tool_available?("pip")
  describe Licensed::Sources::Pip do
    let(:fixtures)  { File.expand_path("../../fixtures/pip", __FILE__) }
    let(:config)   { Licensed::AppConfiguration.new({ "source_path" => Dir.pwd, "python" => { "virtual_env_dir" => "test/fixtures/pip/venv" } }) }
    let(:source)   { Licensed::Sources::Pip.new(config) }

    describe "enabled?" do
      it "is true if pip source is available" do
        Dir.chdir(fixtures) do
          assert source.enabled?
        end
      end

      it "is false if pip source is not available" do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            refute source.enabled?
          end
        end
      end
    end

    describe "dependencies" do
      it "detects explicit dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "Jinja2" }
          assert dep
          assert_equal "3.0.0", dep.version
          assert_equal "pip", dep.record["type"]
          assert dep.record["homepage"]
          assert dep.record["summary"]
        end
      end

      it "detects transitive dependencies" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "MarkupSafe" }
          assert dep
          assert_equal "pip", dep.record["type"]
          assert dep.record["homepage"]
          assert dep.record["summary"]
        end
      end

      it "finds license contents from .dist-info/license_files" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "datadog" }
          assert dep.path.end_with?("license_files")
          refute_empty dep.license_files
        end
      end

      it "finds hatch build backend license contents from .dist-info/licenses" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "nbconvert" }
          assert dep.path.end_with?("licenses")
          refute_empty dep.license_files
        end
      end

      it "does not parse metadata from content" do
        Dir.chdir fixtures do
          dep = source.dependencies.detect { |d| d.name == "scipy" }
          assert dep.record.licenses.any? { |l| l.text.include?("Name: GCC runtime library") }
        end
      end
    end
  end
end
