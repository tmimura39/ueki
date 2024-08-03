# frozen_string_literal: true

require_relative "lib/ueki/version"

Gem::Specification.new do |spec|
  spec.name = "ueki"
  spec.version = Ueki::VERSION
  spec.authors = ["Tomohiko Mimura"]
  spec.email = ["mito.5525@gmail.com"]

  spec.summary = "Module to assist in creating your Own HTTP client library"
  spec.description = 'Ueki provides "simple request method" and "error exception class definition and handling"'
  spec.homepage = "https://github.com/tmimura39/ueki"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/tree/main/CHANGELOG.md"

  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
