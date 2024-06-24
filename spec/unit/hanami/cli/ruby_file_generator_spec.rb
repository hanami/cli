# frozen_string_literal: true

RSpec.describe Hanami::CLI::RubyFileGenerator do
  describe ".class" do
    describe "no methods" do
      describe "top-level" do
        it "generates class without parent class" do
          expect(
            described_class.class("Greeter")
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

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
              parent_class: "BaseService",
            ).to_s
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter < BaseService
                end
              OUTPUT
            )
          )
        end
      end

      describe "with single module" do
        it "generates class without parent class" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              modules: %w[Services],
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

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
              parent_class: "BaseService",
              modules: %w[Services]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Services
                  class Greeter < BaseService
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
                # frozen_string_literal: true

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
              parent_class: "BaseService",
              modules: %w[Admin Services]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

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
                # frozen_string_literal: true

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
              parent_class: "BaseService",
              modules: %w[Internal Admin Services]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

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

    describe "with methods" do
      describe "top-level" do
        it "generates class without parent class and call method with no args" do
          expect(
            described_class.class("Greeter", methods: {call: nil})
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter
                  def call
                  end
                end
              OUTPUT
            )
          )
        end

        it "generates class with parent class and call method with 1 arg" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              parent_class: "BaseService",
              methods: {call: ["args"]}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter < BaseService
                  def call(args)
                  end
                end
              OUTPUT
            )
          )
        end
      end

      describe "with single module" do
        it "generates class without parent class and call methods with 2 args" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              modules: %w[Services],
              methods: {call: %w[request response]}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Services
                  class Greeter
                    def call(request, response)
                    end
                  end
                end
              OUTPUT
            )
          )
        end

        it "generates class with parent class and call method with required keyword args" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              parent_class: "BaseService",
              modules: %w[Services],
              methods: {call: %w[request: response:]}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Services
                  class Greeter < BaseService
                    def call(request:, response:)
                    end
                  end
                end
              OUTPUT
            )
          )
        end
      end

      describe "with two modules" do
        it "generates class without parent class and call method with mix of args" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              modules: %w[Admin Services],
              methods: {call: ["env", "request:", "response:", "context: nil"]}
            ).to_s
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Admin
                  module Services
                    class Greeter
                      def call(env, request:, response:, context: nil)
                      end
                    end
                  end
                end
              OUTPUT
            )
          )
        end

        it "generates class with parent class and two methods" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              parent_class: "BaseService",
              modules: %w[Admin Services],
              methods: {initialize: ["context"], call: ["args"]}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Admin
                  module Services
                    class Greeter < BaseService
                      def initialize(context)
                      end

                      def call(args)
                      end
                    end
                  end
                end
              OUTPUT
            )
          )
        end
      end

      describe "with three modules" do
        it "generates class without parent class, with ivars and method" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              modules: %w[Internal Admin Services],
              ivars: [:@name, :@birthdate],
              methods: {call: [:env]}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Internal
                  module Admin
                    module Services
                      class Greeter
                        def initialize(name:, birthdate:)
                          @name = name
                          @birthdate = birthdate
                        end

                        def call(env)
                        end

                        private

                        attr_reader :name, :birthdate
                      end
                    end
                  end
                end
              OUTPUT
            )
          )
        end

        it "raises error when ivars don't lead with @" do
          expect {
            described_class.class("Greeter", ivars: [:name])
          }.to(raise_error(Hanami::CLI::RubyFileGenerator::InvalidInstanceVariablesError))
        end

        it "raises error when 'initialize' method is specified and ivars are present" do
          expect {
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              ivars: [:@name],
              methods: {initialize: nil}
            )
          }.to(raise_error(Hanami::CLI::RubyFileGenerator::DuplicateInitializeMethodError))
        end

        it "generates class with parent class, and requires" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              parent_class: "BaseService",
              modules: %w[Internal Admin Services],
              requires: ["roobi/fake"]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                require "roobi/fake"

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

      describe "with includes" do
        it "generates class with includes" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              includes: ["Enumerable", %(Import["external.api"])]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter
                  include Enumerable
                  include Import["external.api"]
                end
              OUTPUT
            )
          )
        end

        it "generates class with includes and ivars" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              includes: ["Enumerable", %(Import["external.api"])],
              ivars: [:@name]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter
                  include Enumerable
                  include Import["external.api"]

                  def initialize(name:)
                    @name = name
                  end

                  private

                  attr_reader :name
                end
              OUTPUT
            )
          )
        end

        it "generates class with includes and one method" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              includes: ["Enumerable", %(Import["external.api"])],
              methods: {call: ["name"]}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter
                  include Enumerable
                  include Import["external.api"]

                  def call(name)
                  end
                end
              OUTPUT
            )
          )
        end
      end

      describe "with inline syntax name for parent, module, class" do
        it "generates class with inline-syntax" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Services::Greeter",
              parent_class: "Internal::BaseService",
              modules: ["Internal::Admin"]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                module Internal::Admin
                  class Services::Greeter < Internal::BaseService
                  end
                end
              OUTPUT
            )
          )
        end
      end

      describe "with magic comment" do
        it "generates class with custom magic comment" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              modules: ["Internal"],
              magic_comments: {value: true}
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true
                # value: true

                module Internal
                  class Greeter
                  end
                end
              OUTPUT
            )
          )
        end
      end

      describe "with top contents" do
        it "generates simple class with only top contents as comment" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Foo",
              top_contents: ["# code goes here"]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Foo
                  # code goes here
                end
              OUTPUT
            )
          )
        end

        it "generates class with top contents in correct spot" do
          expect(
            Hanami::CLI::RubyFileGenerator.class(
              "Greeter",
              includes: ["Validatable"],
              ivars: [:@name],
              top_contents: ["before_call :validate"]
            )
          ).to(
            eq(
              <<~OUTPUT
                # frozen_string_literal: true

                class Greeter
                  include Validatable

                  before_call :validate

                  def initialize(name:)
                    @name = name
                  end

                  private

                  attr_reader :name
                end
              OUTPUT
            )
          )
        end
      end
    end

    it "generates class with sorted custom magic comments, including frozen_string_literal" do
      expect(
        Hanami::CLI::RubyFileGenerator.class(
          "Greeter",
          modules: ["Internal"],
          magic_comments: {abc: 123, value: true}
        )
      ).to(
        eq(
          <<~OUTPUT
            # abc: 123
            # frozen_string_literal: true
            # value: true

            module Internal
              class Greeter
              end
            end
          OUTPUT
        )
      )
    end

    it "fails to generate unparseable ruby code" do
      expect { described_class.class("%%Greeter") }.to(
        raise_error(Hanami::CLI::RubyFileGenerator::GeneratedUnparseableCodeError)
      )
    end

    describe ".module" do
      describe "no methods" do
        describe "without frozen_string_literal" do
          describe "top-level" do
            it "generates module by itself" do
              expect(
                described_class.module("Greetable")
              ).to(
                eq(
                  <<~OUTPUT
                    # frozen_string_literal: true

                    module Greetable
                    end
                  OUTPUT
                )
              )
            end

            it "generates modules nested in a module, from arrray" do
              expect(
                described_class.module(%w[External Greetable])
              ).to(
                eq(
                  <<~OUTPUT
                    # frozen_string_literal: true

                    module External
                      module Greetable
                      end
                    end
                  OUTPUT
                )
              )
            end

            it "generates modules nested in a module, from list" do
              expect(
                described_class.module("Admin", "External", "Greetable")
              ).to(
                eq(
                  <<~OUTPUT
                    # frozen_string_literal: true

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
    end
  end
end
