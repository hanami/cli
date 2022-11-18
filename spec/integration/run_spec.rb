# frozen_string_literal: true

require "open3"

RSpec.describe "bin/hanami", :app do
  def output
    Open3.capture3({"HANAMI_ENV" => hanami_env}, "bin/hanami #{args.join(' ')}", chdir: app.root)
  end

  let(:hanami_env) { nil }
  let(:stdout) { output[0] }
  let(:stderr) { output[1] }
  let(:exit_code) { output[2].exitstatus }

  context "no args" do
    let(:args) { [] }

    it "prints out usage" do
      expect(stderr).to include("install")
      expect(stderr).to include("console")
      expect(stderr).to include("generate")
      # expect(stderr).to include("db [SUBCOMMAND]")
    end
  end

  context "error" do
    context "with unknown command" do
      let(:args) { %w[unknown command] }

      it "prints help and exits with error code" do
        expect(exit_code).to be(1)
        expect(stderr).to include("Commands:")
      end
    end

    context "when sub command raises an error" do
      let(:args) { %w[generate action home.index --slice=foo] }

      it "prints error message and exits with error code" do
        expect(exit_code).to be(1)
        expect(stderr).to include("slice `foo' is missing")
      end
    end
  end

  # context "db" do
  #   let(:args) { ["db"] }
  #
  #   it "prints put db usage" do
  #     expect(stderr).to include("db create")
  #     expect(stderr).to include("db structure [SUBCOMMAND]")
  #   end
  # end

  context "console" do
    context "irb" do
      let(:args) { ["console"] }

      xit "starts irb console" do
        expect(stdout).to include("test[development]")
      end
    end

    context "defaulting to pry when it's present" do
      let(:args) { ["console"] }

      it "starts pry console" do
        expect(stdout).to include("test[development]")
      end
    end

    context "pry" do
      let(:args) { ["console --engine pry"] }

      it "starts pry console" do
        expect(stdout).to include("test[development]")
      end
    end

    describe "hanami environment" do
      context "HANAMI_ENV is present in the environment" do
        let(:hanami_env) { "production" }

        context "forced env option absent" do
          let(:args) { ["console"] }

          it "respects HANAMI_ENV" do
            expect(stdout).to include("test[production]")
          end
        end
      end

      context "HANAMI_ENV is absent from the environment" do
        let(:hanami_env) { nil }

        context "forced env option absent" do
          let(:args) { ["console"] }

          it "defaults to development" do
            expect(stdout).to include("test[development]")
          end
        end
      end
    end
  end
end
