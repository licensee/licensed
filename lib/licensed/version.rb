# frozen_string_literal: true
require "open3"

module Licensed
  VERSION = begin
    root = File.expand_path("../..", __dir__)
    loaded_spec = Gem.loaded_specs["licensed"]
    loaded_from = loaded_spec&.loaded_from && File.expand_path(loaded_spec.loaded_from)

    # Published gems should report the version stored in gem metadata. Source
    # checkouts need to ignore Bundler's path gemspec so development builds can
    # infer the next release version from git tags.
    if loaded_spec&.version && loaded_from != File.join(root, "licensed.gemspec")
      loaded_spec.version.to_s
    else
      git_error = nil

      begin
        output, status = Open3.capture2e(
          "git",
          "describe",
          "--tags",
          chdir: root
        )
      rescue SystemCallError => e
        git_error = e.message
      end

      if status&.success?
        described_version = output.strip.delete_prefix("v")

        # Exact tags build that tag's version. Commits after a tag build the
        # next patch version Homebrew and the release workflow should expect.
        if (match = described_version.match(/\A(.+)-\d+-g[0-9a-f]+(?:-dirty)?\z/))
          match[1].sub(/\d+\z/) { |segment| (segment.to_i + 1).to_s.rjust(segment.length, "0") }
        else
          described_version
        end
      elsif File.exist?(lockfile = File.join(root, "Gemfile.lock"))
        # Shallow CI checkouts do not fetch tags in the broad test matrix. The
        # lockfile keeps Bundler setup fast and deterministic there.
        lockfile_version = File.read(lockfile)[/^    licensed \(([^)]+)\)$/, 1]
        raise "Unable to determine licensed version from Gemfile.lock" unless lockfile_version

        lockfile_version
      else
        error_output = output.to_s.strip
        raise "Unable to determine licensed version" if git_error.to_s.empty? && error_output.empty?

        raise "Unable to determine licensed version: #{git_error || error_output}"
      end
    end
  end.freeze

  def self.previous_major_versions
    major_version = Gem::Version.new(Licensed::VERSION).segments.first
    (1...major_version).to_a
  end
end
