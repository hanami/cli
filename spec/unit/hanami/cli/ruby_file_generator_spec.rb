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

  it "fails to generate unparseable ruby code" do
    expect { Hanami::CLI::RubyFileGenerator.new(class_name: "%%Greeter").call }.to(
      raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)
    )

    expect { Hanami::CLI::RubyFileGenerator.new(modules: ["1Greeter"]).call }.to(
      raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)
    )
  end
end
