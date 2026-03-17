# frozen_string_literal: true

require "English"
require "json"
require "parallel"

module Licensed
  module Sources
    class Pip < Source
      def enabled?
        !pip_command.empty? && Licensed::Shell.tool_available?(pip_command.join(""))
      end

      def enumerate_dependencies
        packages.map do |package|
          Dependency.new(
            name: package["Name"],
            version: package["Version"],
            path: package_license_location(package),
            metadata: {
              "type"        => self.class.type,
              "summary"     => package["Summary"],
              "homepage"    => homepage(package)
            }
          )
        end
      end

      protected

      # Returns the command to run pip
      def pip_command
        return [] unless virtual_env_dir
        Array(File.join(virtual_env_dir, "bin", "pip"))
      end

      private

      # Returns the location of license files in the package, checking for the inclusion of a new `license_files`
      # folder per https://peps.python.org/pep-0639/
      def package_license_location(package)
        dist_info = package_dist_info_path(package)

        license_path = ["license_files", "licenses"]
          .map { |directory| File.join(dist_info, directory) }
          .find { |path| File.exist?(path) }

        license_path || dist_info
      end

      # Returns the package's .dist-info path, matching case-insensitively to support
      # filesystems where installed wheel metadata directories may be lowercase.
      def package_dist_info_path(package)
        expected = "#{package["Name"].tr("-", "_")}-#{package["Version"]}.dist-info".downcase
        dist_infos = Dir.glob(File.join(package["Location"], "*.dist-info"))
        dist_infos.find { |path| File.basename(path).downcase == expected } ||
          File.join(package["Location"], "#{package["Name"].tr("-", "_")}-#{package["Version"]}.dist-info")
      end

      # Returns parsed information for all packages used by the project,
      # using `pip list` to determine what packages are used and `pip show`
      # to gather package information
      def packages
        # Handle case where package show command actually includes the separator inside the package info
        # This is a workaround for the fact that pip show does not have a way to specify a custom separator
        # Not counting on the package separator here but instead doing them one by one.
        all_packages = Parallel.map(package_names, in_threads: 4) { |package| pip_show_command(package) }

        all_packages.reduce([]) do |accum, val|
          accum << parse_package_info(val)
        end
      end

      # Returns the names of all of the packages used by the current project,
      # as returned from `pip list`
      def package_names
        @package_names ||= begin
          JSON.parse(pip_list_command).map { |package| package["name"] }
        rescue JSON::ParserError => e
          message = "Licensed was unable to parse the output from 'pip list'. JSON Error: #{e.message}"
          raise Licensed::Sources::Source::Error, message
        end
      end

      # Returns a hash filled with package info parsed from the email-header formatted output
      # returned by `pip show --verbose`, including continuation lines for multi-line fields.
      def parse_package_info(package_info)
        current_key = nil

        package_info.lines.each_with_object(Hash.new(0)) do |pkg, a|
          if pkg.match?(/^\s/)
            if current_key
              current_value = a[current_key]
              continuation = pkg.strip
              a[current_key] = if current_value.to_s.empty?
                continuation
              else
                "#{current_value}\n#{continuation}"
              end
            end
            next
          end

          k, v = pkg.split(":", 2)
          next if k.nil? || k.empty?

          current_key = k.strip
          a[current_key] = v&.strip
        end
      end

      # Returns the output from `pip list --format=json`
      def pip_list_command
        Licensed::Shell.execute(*pip_command, "--disable-pip-version-check", "list", "--format=json")
      end

      # Returns the output from `pip show <package> <package> ...`
      def pip_show_command(package)
        Licensed::Shell.execute(*pip_command, "--disable-pip-version-check", "show", "--verbose", package)
      end

      # Returns the package homepage from pip package metadata
      def homepage(package)
        home_page = package["Home-page"]
        return home_page unless home_page.to_s.empty?

        homepage_from_project_urls(package["Project-URL"] || package["Project-URLs"])
      end

      # Returns best-effort homepage URL extracted from Project-URL(s) metadata
      # With priority given to Home > Repository > Source, otherwise the first URL
      def homepage_from_project_urls(project_urls)
        return if project_urls.to_s.empty?

        entries = project_urls
          .split("\n")
          .map(&:strip)
          .reject(&:empty?)

        candidates = entries.map do |entry|
          label, url = entry.split(",", 2).map { |value| value&.strip }
          [label, url]
        end.select { |_, url| url&.match?(%r{^https?://}) }

        preferred = candidates.find { |label, _| label&.match?(/home/i) } ||
          candidates.find { |label, _| label&.match?(/repo/i) } ||
          candidates.find { |label, _| label&.match?(/source/i) }
        preferred&.last || candidates.first&.last
      end

      def virtual_env_dir
        return @virtual_env_dir if defined?(@virtual_env_dir)
        @virtual_env_dir = begin
          python_config = config["python"]
          return unless python_config.is_a?(Hash)

          venv_dir = python_config["virtual_env_dir"]
          File.expand_path(venv_dir, config.root) if venv_dir
        end
      end
    end
  end
end
