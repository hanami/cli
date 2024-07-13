# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../naming"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.2.0
          # @api private
          class Repo < Command
            argument :name, required: true, desc: "Repo name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(books               (MyApp::Repos::BooksRepo)),
              %(books/drafts_repo   (MyApp::Repos::Books::DraftsRepo)),
              %(books --slice=admin  (Admin::Repos::BooksRepo)),
            ]

            # @since 2.2.0
            # @api private
            def generator_class
              Generators::App::Repo
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **)
              normalized_name = if name.end_with?("_repo")
                                  name
                                else
                                  "#{inflector.pluralize(name)}_repo"
                                end
              slice = inflector.underscore(Shellwords.shellescape(slice)) if slice

              super(name: normalized_name, slice: slice, **)
            end
          end
        end
      end
    end
  end
end
