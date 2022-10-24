# frozen_string_literal: true

RSpec.describe "bin/hanami", :app do
  def output
    Open3.capture3({"HANAMI_ENV" => hanami_env}, "bin/hanami #{args.join(' ')}", chdir: app.root)
  end

  let(:hanami_env) { nil }

  let(:stdout) do
    output[1]
  end

  context "no args" do
    let(:args) { [] }

    it "prints out usage" do
      expect(stdout).to include("install")
      expect(stdout).to include("console")
      expect(stdout).to include("generate")
      # expect(stdout).to include("db [SUBCOMMAND]")
    end
  end

  # context "db" do
  #   let(:args) { ["db"] }
  #
  #   it "prints put db usage" do
  #     expect(stdout).to include("db create")
  #     expect(stdout).to include("db structure [SUBCOMMAND]")
  #   end
  # end

  context "console" do
    context "irb" do
      let(:args) { ["console"] }

      xit "starts irb console" do
        expect(output[0]).to include("test[development]")
      end
    end

    context "defaulting to pry when it's present" do
      let(:args) { ["console"] }

      it "starts pry console" do
        expect(output[0]).to include("test[development]")
      end
    end

    context "pry" do
      let(:args) { ["console --engine pry"] }

      it "starts pry console" do
        expect(output[0]).to include("test[development]")
      end
    end

    describe "hanami environment" do
      context "HANAMI_ENV is present in the environment" do
        let(:hanami_env) { "production" }

        context "forced env option absent" do
          let(:args) { ["console"] }

          it "respects HANAMI_ENV" do
            expect(output[0]).to include("test[production]")
          end
        end
      end

      context "HANAMI_ENV is absent from the environment" do
        let(:hanami_env) { nil }

        context "forced env option absent" do
          let(:args) { ["console"] }

          it "defaults to development" do
            expect(output[0]).to include("test[development]")
          end
        end
      end
    end
  end
end
