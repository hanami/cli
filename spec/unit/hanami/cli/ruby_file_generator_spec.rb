# frozen_string_literal: true

RSpec.describe Hanami::CLI::RubyFileGenerator do
  describe "class generation" do
    describe "without modules" do
      it "generates class without parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(class_name: "Greeter").call
        ).to(
          eq(
            <<~OUTPUT
              class Greeter
              end
            OUTPUT
          )
        )
      end

      it "generates class with parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            parent_class_name: "BaseService",
          ).call
        ).to(
          eq(
            <<~OUTPUT
              class Greeter < BaseService
              end
            OUTPUT
          )
        )
      end

      it "generates class with parent class and body" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            parent_class_name: "BaseService",
            body: %w[foo bar]
          ).call
        ).to(
          eq(
            <<~OUTPUT
              class Greeter < BaseService
                foo
                bar
              end
            OUTPUT
          )
        )
      end
    end

    describe "with 1 module" do
      it "generates class without parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            modules: %w[Services],
          ).call
        ).to(
          eq(
            <<~OUTPUT
              module Services
                class Greeter
                end
              end
            OUTPUT
          )
        )
      end

      it "generates class with parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Services]
          ).call
        ).to(
          eq(
            <<~OUTPUT
              module Services
                class Greeter < BaseService
                end
              end
            OUTPUT
          )
        )
      end

      it "generates class with parent class, body and headers" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Services],
            headers: ["# hello world"],
            body: %w[foo bar]
          ).call
        ).to(
          eq(
            <<~OUTPUT
              # hello world

              module Services
                class Greeter < BaseService
                  foo
                  bar
                end
              end
            OUTPUT
          )
        )
      end
    end

    describe "with two modules" do
      it "generates class without parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            modules: %w[Admin Services],
          ).call
        ).to(
          eq(
            <<~OUTPUT
              module Admin
                module Services
                  class Greeter
                  end
                end
              end
            OUTPUT
          )
        )
      end

      it "generates class with parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Admin Services]
          ).call
        ).to(
          eq(
            <<~OUTPUT
              module Admin
                module Services
                  class Greeter < BaseService
                  end
                end
              end
            OUTPUT
          )
        )
      end
    end

    describe "with three modules" do
      it "generates class without parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            modules: %w[Internal Admin Services]
          ).call
        ).to(
          eq(
            <<~OUTPUT
              module Internal
                module Admin
                  module Services
                    class Greeter
                    end
                  end
                end
              end
            OUTPUT
          )
        )
      end

      it "generates class with parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.new(
            class_name: "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Internal Admin Services]
          ).call
        ).to(
          eq(
            <<~OUTPUT
              module Internal
                module Admin
                  module Services
                    class Greeter < BaseService
                    end
                  end
                end
              end
            OUTPUT
          )
        )
      end
    end
  end

  describe "module generation" do
    describe "without frozen_string_literal" do
      describe "top-level" do
        it "generates module by itself" do
          expect(
            Hanami::CLI::RubyFileGenerator.new(modules: ["Greetable"]).call
          ).to(
            eq(
              <<~OUTPUT
                module Greetable
                end
              OUTPUT
            )
          )
        end

        it "generates modules nested in a module, from array" do
          expect(
            Hanami::CLI::RubyFileGenerator.new(modules: %w[External Greetable]).call
          ).to(
            eq(
              <<~OUTPUT
                module External
                  module Greetable
                  end
                end
              OUTPUT
            )
          )
        end

        it "generates modules nested in a module, from array with headers and body" do
          expect(
            Hanami::CLI::RubyFileGenerator.new(
              modules: %w[External Greetable],
              headers: ["# hello world"],
              body: %w[foo bar]
            ).call
          ).to(
            eq(
              <<~OUTPUT
                # hello world

                module External
                  module Greetable
                    foo
                    bar
                  end
                end
              OUTPUT
            )
          )
        end

        it "generates modules nested in a module, multiple levels" do
          expect(
            Hanami::CLI::RubyFileGenerator.new(modules: %w[Admin External Greetable]).call
          ).to(
            eq(
              <<~OUTPUT
                module Admin
                  module External
                    module Greetable
                    end
                  end
                end
              OUTPUT
            )
          )
        end
      end
    end
  end

  describe "block generation" do
    it "generates a simple block" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(block_signature: "configure").call
      ).to(
        eq(
          <<~OUTPUT
            configure do
            end
          OUTPUT
        )
      )
    end

    it "generates a block with signature arguments" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(block_signature: "configure env, settings").call
      ).to(
        eq(
          <<~OUTPUT
            configure env, settings do
            end
          OUTPUT
        )
      )
    end

    it "generates a block with body" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(
          block_signature: "configure",
          body: ["puts 'hello'", "puts 'world'"]
        ).call
      ).to(
        eq(
          <<~OUTPUT
            configure do
              puts 'hello'
              puts 'world'
            end
          OUTPUT
        )
      )
    end

    it "generates a block with empty lines in body" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(
          block_signature: "configure",
          body: ["puts 'start'", "", "puts 'end'"]
        ).call
      ).to(
        eq(
          <<~OUTPUT
            configure do
              puts 'start'

              puts 'end'
            end
          OUTPUT
        )
      )
    end

    it "generates a block with headers" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(
          block_signature: "configure",
          body: ["puts 'hello'"],
          headers: ["# frozen_string_literal: true"]
        ).call
      ).to(
        eq(
          <<~OUTPUT
            # frozen_string_literal: true

            configure do
              puts 'hello'
            end
          OUTPUT
        )
      )
    end

    it "generates a block inside modules" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(
          block_signature: "configure",
          body: ["puts 'hello'"],
          modules: %w[App Config]
        ).call
      ).to(
        eq(
          <<~OUTPUT
            module App
              module Config
                configure do
                  puts 'hello'
                end
              end
            end
          OUTPUT
        )
      )
    end

    it "generates a block inside modules with headers" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(
          block_signature: "configure",
          body: ["puts 'hello'"],
          modules: ["App"],
          headers: ["# frozen_string_literal: true"]
        ).call
      ).to(
        eq(
          <<~OUTPUT
            # frozen_string_literal: true

            module App
              configure do
                puts 'hello'
              end
            end
          OUTPUT
        )
      )
    end

    it "generates complex block with signature args, modules, headers and body" do
      expect(
        Hanami::CLI::RubyFileGenerator.new(
          block_signature: "configure app, env",
          body: ["puts 'configuring'", "app.setup", "", "env.load"],
          modules: %w[MyApp Config],
          headers: ["# frozen_string_literal: true", "# Configuration block"]
        ).call
      ).to(
        eq(
          <<~OUTPUT
            # frozen_string_literal: true
            # Configuration block

            module MyApp
              module Config
                configure app, env do
                  puts 'configuring'
                  app.setup

                  env.load
                end
              end
            end
          OUTPUT
        )
      )
    end
  end

  it "fails when both class_name and block_signature are specified" do
    expect {
      Hanami::CLI::RubyFileGenerator.new(class_name: "MyClass", block_signature: "configure")
    }.to raise_error(ArgumentError, "cannot specify both class_name and block_signature")
  end

  it "fails when parent_class_name is specified without class_name" do
    expect {
      Hanami::CLI::RubyFileGenerator.new(parent_class_name: "BaseService")
    }.to raise_error(ArgumentError, "class_name is required when parent_class_name is specified")
  end

  it "fails to generate unparseable ruby code" do
    expect {
      Hanami::CLI::RubyFileGenerator.new(class_name: "%%Greeter").call
    }.to raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)

    expect {
      Hanami::CLI::RubyFileGenerator.new(modules: ["1Greeter"]).call
    }.to raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)

    expect {
      Hanami::CLI::RubyFileGenerator.new(block_signature: "%%invalid").call
    }.to raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)
  end
end
