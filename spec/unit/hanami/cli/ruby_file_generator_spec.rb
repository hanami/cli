# frozen_string_literal: true

RSpec.describe Hanami::CLI::RubyFileGenerator do
  describe ".class" do
    describe "without modules" do
      it "generates class without parent class" do
        expect(
          Hanami::CLI::RubyFileGenerator.class("Greeter")
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            parent_class_name: "BaseService",
          ).to_s
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            parent_class_name: "BaseService",
            body: %w[foo bar]
          ).to_s
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            modules: %w[Services],
          )
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Services]
          )
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Services],
            headers: ["# hello world"],
            body: %w[foo bar]
          )
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            modules: %w[Admin Services],
          )
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Admin Services]
          )
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            modules: %w[Internal Admin Services]
          )
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
          Hanami::CLI::RubyFileGenerator.class(
            "Greeter",
            parent_class_name: "BaseService",
            modules: %w[Internal Admin Services]
          )
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

  describe ".module" do
    describe "without frozen_string_literal" do
      describe "top-level" do
        it "generates module by itself" do
          expect(
            Hanami::CLI::RubyFileGenerator.module("Greetable")
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
            Hanami::CLI::RubyFileGenerator.module(%w[External Greetable])
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
            Hanami::CLI::RubyFileGenerator.module(
              %w[External Greetable],
              headers: ["# hello world"],
              body: %w[foo bar]
            )
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

        it "generates modules nested in a module, from list" do
          expect(
            Hanami::CLI::RubyFileGenerator.module("Admin", "External", "Greetable")
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
    expect { Hanami::CLI::RubyFileGenerator.class("%%Greeter") }.to(
      raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)
    )

    expect { Hanami::CLI::RubyFileGenerator.module("1Greeter") }.to(
      raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)
    )
  end
end
