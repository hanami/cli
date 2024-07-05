# frozen_string_literal: true

require "hanami/devtools/integration/files"
require "hanami/devtools/integration/with_tmp_directory"
require "json"
require "tmpdir"
require "zeitwerk"

module RSpec
  module Support
    module WithTmpDirectory
      private

      def make_tmp_directory
        Pathname(Dir.mktmpdir).tap do |dir|
          (@made_tmp_dirs ||= []) << dir
        end
      end
    end

    module App
    end
  end
end

RSpec.shared_context "App integration" do
  let(:app_modules) { %i[Test TestApp Admin Main] }
end

def autoloaders_teardown!
  ObjectSpace.each_object(Zeitwerk::Loader) do |loader|
    loader.unregister if loader.dirs.any? { |dir|
      dir.include?("/spec/") || dir.include?(Dir.tmpdir) ||
      dir.include?("/slices/") || dir.include?("/app")
    }
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Files, :app_integration
  config.include RSpec::Support::WithTmpDirectory, :app_integration
  config.include RSpec::Support::App, :app_integration
  config.include_context "App integration", :app, :app_integration

  prepare_example = proc do
    # Conditionally assign in case these have been assigned earlier for specific example groups
    @load_paths ||= $LOAD_PATH.dup
    @loaded_features ||= $LOADED_FEATURES.dup
  end

  tidy_example = proc do
    autoloaders_teardown!

    Hanami.instance_variable_set(:@_bundled, {})
    Hanami.remove_instance_variable(:@_app) if Hanami.instance_variable_defined?(:@_app)

    # Clear cached DB gateways across slices
    Hanami::Providers::DB.cache.clear

    $LOAD_PATH.replace(@load_paths)

    # Remove example-specific LOADED_FEATURES added when running each example
    new_features_to_keep = ($LOADED_FEATURES - @loaded_features).tap { |feats|
      feats.delete_if do |path|
        path =~ %r{hanami/(setup|prepare|boot|application/container/providers)} ||
          path.include?(SPEC_ROOT.to_s) ||
          path.include?(Dir.tmpdir)
      end
    }
    $LOADED_FEATURES.replace(@loaded_features + new_features_to_keep)

    app_modules.each do |app_module_name|
      next unless Object.const_defined?(app_module_name)

      Object.const_get(app_module_name).tap do |mod|
        mod.constants.each do |name|
          mod.send(:remove_const, name)
        end
      end

      Object.send(:remove_const, app_module_name)
    end
  end

  config.before(:each, :app) { instance_eval(&prepare_example) }
  config.before(:each, :app_integration) { instance_eval(&prepare_example) }
  config.after(:each, :app) { instance_eval(&tidy_example) }
  config.after(:each, :app_integration) { instance_eval(&tidy_example) }

  config.after :all do
    if instance_variable_defined?(:@made_tmp_dirs)
      Array(@made_tmp_dirs).each do |dir|
        FileUtils.remove_entry dir
      end
    end
  end
end
