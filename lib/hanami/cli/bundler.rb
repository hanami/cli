# frozen_string_literal: true

require "bundler"
require "open3"
require "etc"
require "dry/files"
require_relative "./system_call"
require_relative "./errors"

module Hanami
  module CLI
    class Bundler
      BUNDLE_GEMFILE = "BUNDLE_GEMFILE"
      private_constant :BUNDLE_GEMFILE

      DEFAULT_GEMFILE_PATH = "Gemfile"
      private_constant :DEFAULT_GEMFILE_PATH

      def self.require(*groups)
        return unless File.exist?(ENV.fetch(BUNDLE_GEMFILE) { DEFAULT_GEMFILE_PATH })

        ::Bundler.require(*groups)
      end

      def initialize(fs: Dry::Files.new, system_call: SystemCall.new)
        @fs = fs
        @system_call = system_call
      end

      def install
        parallelism_level = Etc.nprocessors
        bundle "install --jobs=#{parallelism_level} --quiet --no-color"
      end

      def install!
        install.tap do |result|
          raise BundleInstallError.new(result.err) unless result.successful?
        end
      end

      def exec(cmd, env: nil, &blk)
        bundle("exec #{cmd}", env: env, &blk)
      end

      def bundle(cmd, env: nil, &blk)
        bundle_bin = which("bundle")
        hanami_env = "HANAMI_ENV=#{env} " unless env.nil?

        system_call.call("#{hanami_env}#{bundle_bin} #{cmd}",
                         env: {BUNDLE_GEMFILE => fs.expand_path(DEFAULT_GEMFILE_PATH)}, &blk)
      end

      private

      attr_reader :fs

      attr_reader :system_call

      # Adapted from https://stackoverflow.com/a/5471032/498386
      def which(cmd)
        ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
          exe = fs.join(path, cmd)
          return exe if fs.executable?(exe) && !fs.directory?(exe)
        end

        nil
      end
    end
  end
end
